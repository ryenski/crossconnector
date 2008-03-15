require File.dirname(__FILE__) + '/../../test_helper'
require 'admin/project_controller'

# Re-raise errors caught by the controller.
class Admin::ProjectController; def rescue_action(e) raise e end; end

class Admin::ProjectControllerTest < Test::Unit::TestCase
  
  fixtures :subscription_plans, :subscriptions, :homebases, :users, :addresses, :groups, :projects, :addresses_projects, :groups_projects, :addresses_groups, :subscription_plan_priveleges, :subscription_plan_items
  
  def setup
    @controller = Admin::ProjectController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    @emails     = ActionMailer::Base.deliveries
    @emails.clear    
    setup_homebases
  end

  
  def test_list_projects
    simulate_login
    
    get :index
    assert_response :success
    
    assert_equal 4, assigns(:homebase).projects.count
    assert_equal 1, assigns(:homebase).archived_projects.count
    
  end
  
  
  def test_create_project
    simulate_login
    
    get :new
    
    assert_response :success
    assert assigns(:project)
    post :new, :project => {:name => "My new project",
                            :description => "This is a description of my fantastic new project. ",
                            :address_ids => [1,2,3],
                            :group_ids => []}
    
    assert_response :redirect
    assert_equal "Project saved", @response.flash[:notice]
    
    assert_equal 1, @emails.size
    email = @emails.first
    assert_equal 3, email.to.size
    assert_equal "bethany@example.com", email.to[0]
    assert_equal "CrossConnector - My new project", email.subject
    assert_match(/fantastic/, email.body)
    assert_not_nil Project.find_by_name("My new project")
  end
  
  
  def test_edit_project
    simulate_login
    
    get :edit, :permalink => projects(:haiti_project).permalink
    assert_response :success
    
    post :edit, :permalink => projects(:haiti_project).permalink, 
                            :project => {:name => "Project One - Trip to Haiti has been modified",
                            :description => "This is a description of my fantastic project. ",
                            :address_ids => [3,4], #Address 3 & 4
                            :group_ids => [1],   #Group 1 contains Address 1 & 2
                            :resend_email => 1}
    assert_equal "Project saved and email re-sent", @response.flash[:notice]
    assert_response :redirect
    project = Project.find(1)
    assert_match(/modified/, project.name)
    
    
    assert_equal 1, @emails.size
    email = @emails.first
    assert_equal 4, email.to.size
    assert_equal "CrossConnector - Project One - Trip to Haiti has been modified", email.subject
    assert_match(/fantastic/, email.body)
    
    # Can't edit, so redirect
    simulate_login("haiti_leader@example.com", "haiti")
    get :edit, :permalink => projects(:haiti_project, :refresh).permalink
    assert_response :redirect
    
    # Should be able to edit project
    simulate_login("haiti_leader2@example.com", "haiti")
    get :edit, :permalink => projects(:haiti_project, :refresh).permalink
    assert_response :success
    
  end
  
  
  def test_edit_private_project
    simulate_login
    get :edit, :permalink => projects(:haiti_private_project).permalink
    assert_response :success
    
    project = Project.find(projects(:haiti_private_project).id)
    assert_not_nil project.salted_password
    
    post :edit, :permalink => projects(:haiti_private_project).permalink, :project => {:private => 0}
    assert_equal "Project saved", @response.flash[:notice]
    
    project.reload
    assert_equal 0, project.private
    
  end
  
  def test_others_cant_edit_project
    simulate_login("alan@example.com", "haiti")
    get :edit, :permalink => projects(:haiti_project).permalink
    assert_response :redirect
    
    simulate_login("alan@example.com", "covinavineyard")
    get :edit, :permalink => projects(:haiti_project).permalink
    assert_response :redirect
    
    Homebase.current_homebase = Homebase.find(1)
    User.current_user, @request.session[:user] = nil
    get :edit, :permalink => projects(:haiti_project).permalink
    assert_response :redirect
    
    Homebase.current_homebase = Homebase.find(1)
    User.current_user, @request.session[:user] = nil
    
    get :edit, :permalink => projects(:haiti_project).permalink
    assert_response :redirect    
    post :edit, :permalink => projects(:haiti_project).permalink, :project => {:name => "Project One - Trip to Haiti has been modified"}
    assert_response :redirect
    
  end
  
  
  
  def test_delete_project
    simulate_login
    
    get :edit, :permalink => projects(:project_to_delete).permalink
    assert_response :success
    
    post :delete, :permalink => projects(:project_to_delete).permalink
    assert_response :redirect
    assert_equal "Project \"#{projects(:project_to_delete).name}\" deleted", flash[:notice]
    assert_raise(ActiveRecord::RecordNotFound) { Project.find(4) }
    
    # Haiti Editor can't delete project #1 because his can_edit_projects = 0
    User.current_user = User.find(1002)
    @request.session[:user] = User.current_user
    Homebase.current_homebase = Homebase.find(1)
    
    post :delete, :permalink => projects(:haiti_project, :refresh).permalink
    assert_response :redirect
    assert_equal "Sorry, you are not allowed to delete this project.", flash[:notice]
    
    # Second Haiti Editor CAN delete project #1 
    User.current_user = User.find(1005)
    @request.session[:user] = User.current_user
    Homebase.current_homebase = Homebase.find(1)
    post :delete, :permalink => projects(:haiti_project).permalink
    assert_response :redirect
    assert_raise(ActiveRecord::RecordNotFound) { Project.find(1) }
    
  end
  
  def test_cant_edit_archived_project
    simulate_login
    get :edit, :permalink => projects(:archived_project).permalink
    assert_response :redirect
    assert_equal "Unable to edit this project.", flash[:notice]
    
    get :events, :permalink => projects(:archived_project).permalink
    assert_response :redirect
    assert_equal "Unable to edit this project.", flash[:notice]
    
  end
  

  def test_duplicate_project
    simulate_login
    get :duplicate, :permalink => projects(:haiti_project).permalink
    assert_response :success
    assert_equal projects(:haiti_project).id, assigns(:project).id
    
    post :duplicate, :permalink => projects(:haiti_project).permalink, :project => {:name => "Duplicated Project"}, :date => {:year => (Time.now + 6.months).year, :month => (Time.now + 6.months).month, :day => (Time.now + 6.months).day}
    assert_redirected_to :action => :show, :permalink => assigns(:p2).permalink
    
    assert_equal "Duplicated Project", assigns(:p2).name
    assert_equal false, projects(:haiti_project).id == assigns(:p2).id
    assert_equal projects(:haiti_project).homebase, assigns(:p2).homebase
    
    assert_equal 3, assigns(:p2).all_events.size
    
    # Push time to 6.months from now
    expected_time = Time.at(Time.now + 6.months).at_midnight
    assert_equal expected_time, assigns(:date_shift)

    # Test that the start_date is 6 months from now
    assert_equal expected_time, assigns(:start_date)
    
    # Test the event dates
    assert_equal expected_time, assigns(:p2).all_events.first.start_date
    assert_equal (projects(:haiti_project).all_events.first.start_date + assigns(:date_diff)), assigns(:p2).all_events.first.start_date
    #assert_equal (projects(:haiti_project).all_events.first.end_date + assigns(:date_diff)), assigns(:p2).all_events.first.end_date
    assert_equal (projects(:haiti_project).all_events.last.start_date + assigns(:date_diff)), assigns(:p2).all_events.last.start_date
  end
  
  # Test that we can set events to earlier than the original
  def test_duplicate_project_with_earlier_events
    simulate_login
    post :duplicate, :permalink => projects(:haiti_project).permalink, :project => {:name => "Duplicated Project"}, :date => {:year => (Time.now).year, :month => (Time.now).month, :day => (Time.now).day}
    assert_redirected_to :action => :show, :permalink => assigns(:p2).permalink
    assert_equal projects(:haiti_project).id, assigns(:project).id
    
    expected_time = Time.at(Time.now).at_midnight
    # Test the event dates
    #assert_equal expected_time, assigns(:p2).all_events.first.start_date
    assert_equal (projects(:haiti_project).all_events.first.start_date + assigns(:date_diff)), assigns(:p2).all_events.first.start_date
    assert_equal (projects(:haiti_project).all_events.last.start_date + assigns(:date_diff)), assigns(:p2).all_events.last.start_date
  end
  
  def test_duplicate_archived_project
    simulate_login
    post :duplicate, :permalink => projects(:archived_project).permalink, :project => {:name => "Copied Archived Project"}, :date => {:year => (Time.now).year, :month => (Time.now).month, :day => (Time.now).day}
    assert_equal "Project duplicated", assigns(:flash)[:notice]
    assert_redirected_to :action => :show, :permalink => "copied-archived-project"
    assert_equal projects(:archived_project).id, assigns(:project).id
    
    assert_equal "Copied Archived Project", assigns(:p2).name
    assert_equal false, assigns(:p2).archived?
  end
  
  def test_duplicate_when_project_limit_exceeded
    @request.host = "free.crossconnector.com"
    simulate_login("free@example.com", "free")
    assert_equal 1, @homebase.projects_limit
    assert_equal true, @homebase.within_projects_limit?
    assert_equal 1, homebases(:free).projects.count
    assert_equal false, @homebase.can_create_projects?
    
    @request.env["HTTP_REFERER"] = "/bogus/referrer"
    post :duplicate, :permalink => projects(:free_project_one).permalink, :project => {:name => "Too Many Projects"}, :date => {:year => (Time.now).year, :month => (Time.now).month, :day => (Time.now).day}
    assert_response :redirect
    
    assert_redirected_to "/bogus/referrer"
    
    assert_equal true, assigns(:flash)[:notice].include?("Unable to duplicate this project.")
    
    assert_equal 1, homebases(:free).projects.count
    assert_equal 1, homebases(:free).projects_limit
    assert_equal true, homebases(:free).within_projects_limit?
  end

  


end
