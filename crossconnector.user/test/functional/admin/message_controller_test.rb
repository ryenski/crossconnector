require File.dirname(__FILE__) + '/../../test_helper'
require 'admin/message_controller'

# Re-raise errors caught by the controller.
class Admin::MessageController; def rescue_action(e) raise e end; end

class Admin::MessageControllerTest < Test::Unit::TestCase
  
  fixtures :subscription_plans, :homebases, :users, :subscriptions, :subscription_plan_priveleges, :subscription_plan_items, :messages, :projects, :addresses, :groups, :addresses_groups, :messages_projects, :addresses_messages, :groups_messages
  
  def setup
    @controller = Admin::MessageController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    @emails     = ActionMailer::Base.deliveries
    @emails.clear
    
    setup_homebases
  end
  

  
  def test_create_message
    simulate_login
    get :new
    assert_response :success
    
    post :new, :message => {:subject => "Brand New Message", 
                            :body => "Text of the body.", 
                            :project_id => 1}
    assert_response :redirect
    @message = Message.find_by_subject("Brand New Message")
    
    assert_not_nil @message
    
    assert_equal "Brand New Message", @message.subject
    assert_not_nil @message.project
    assert_equal projects(:haiti_project).name, @message.project.name
    assert_equal 0, @message.disable_comments
    assert_equal 0, @message.private
    
    #breakpoint
    assert_equal Homebase.current_homebase.id, @message.homebase_id
    assert_equal Homebase.current_homebase.subdomain, @message.homebase.subdomain
    assert_equal User.current_user, @message.created_by

    assert_equal Homebase.current_homebase, assigns(:message).homebase
    assert_equal User.current_user, assigns(:message).created_by
  end
  
  def test_send_message
    simulate_login
    get :new
    assert_response :success
    
    post :new, :message => {:subject => "Message to email", 
                            :body => "Text of the body.", 
                            :project_id => 1,
                            :address_ids => [1,2,3]}

    #assert_equal "Message to email", assigns(:subject)
    # breakpoint
    assert_equal "Message to email", assigns(:message).subject
    assert_equal 1, @emails.size
    assert_equal 3, @emails.first.to.size
    assert_equal "CrossConnector - Message to email", @emails.first.subject
  end
  
  def test_send_message_to_group
    simulate_login
    get :new
    assert_response :success
    
    post :new, :message => {:subject => "Message to my groups", 
                            :body => "Text of the body.", 
                            :project_id => 1,
                            :group_ids => [1,2]}

    #assert_equal "Message to email", assigns(:subject)
    assert_equal 1, @emails.size
    assert_equal 4, @emails.first.to.size
    assert_equal "CrossConnector - Message to my groups", @emails.first.subject
  end
  
  def test_send_message_to_addresses_and_group
    simulate_login
    get :new
    assert_response :success
    
    post :new, :message => {:subject => "Message to my groups", 
                            :body => "Text of the body.", 
                            :project_id => 1,
                            :group_ids => [1,2],
                            :address_ids => [1,4,5,6]}

    #assert_equal "Message to email", assigns(:subject)
    assert_equal 1, @emails.size
    assert_equal 6, @emails.first.to.size
    assert_equal "CrossConnector - Message to my groups", @emails.first.subject
  end
  
  def test_grant_access_to_message
    
    # An leader who CAN edit messages
    simulate_login("haiti_leader2@example.com", "haiti")
    get :show, :permalink => messages(:haiti_message).permalink
    assert_response :success
    get :edit, :permalink => messages(:haiti_message).permalink
    assert_response :success
    
    
    
    simulate_login("ryan@example.com", "haiti")
    post :edit, :permalink => messages(:haiti_message).permalink, :message => {:subject => "Please change the subject", :body => "new body", :group_ids => [], :address_ids => []}
    @updated_message = Message.find(messages(:haiti_message).id)
    
    assert_equal "Please change the subject", @updated_message.subject
    assert_response :redirect
    assert_redirected_to :action => "show", :permalink => @updated_message.permalink

    
    # Site owner looking at his own draft
    simulate_login("ryan@example.com", "haiti")
    get :show, :permalink => messages(:draft_message, :refresh).permalink
    assert_response :success
    get :edit, :permalink => messages(:draft_message, :refresh).permalink
    assert_response :success
    
    # Site owner looking at a private message
    simulate_login("ryan@example.com", "haiti")
    get :show, :permalink => messages(:private_message).permalink
    assert_response :success
    get :edit, :permalink => messages(:private_message).permalink
    assert_response :success
    

    
  end
  
  def test_prevent_access_to_message
    
    # An leader who CAN edit messages, but this is a draft
    simulate_login("haiti_leader2@example.com", "haiti")
    get :edit, :permalink => messages(:draft_message, :refresh).permalink
    #assert_equal "foo", messages(:draft_message, :refresh).permalink
    assert_response :redirect
    get :show, :permalink => messages(:draft_message, :refresh).permalink
    assert_response :redirect
    
    
    # An leader who cannot edit messages, but should still see them
    simulate_login("haiti_leader@example.com", "haiti")
    get :edit, :permalink => messages(:haiti_message).permalink
    assert_response :redirect
    get :show, :permalink => messages(:haiti_message).permalink
    assert_response :success
    
    # Someone logged into another homebase
    simulate_login("alan@example.com", "haiti")
    get :edit, :permalink => messages(:haiti_message).permalink
    assert_response :redirect
    get :show, :permalink => messages(:haiti_message).permalink
    assert_response :redirect

    # Someone logged into another homebase again
    simulate_login("alan@example.com", "covinavineyard")
    get :edit, :permalink => messages(:haiti_message).permalink
    assert_response :redirect
    get :show, :permalink => messages(:haiti_message).permalink
    assert_response :redirect
    
    # Not logged in at all and wrong homebase...
    Homebase.current_homebase = Homebase.find(1)
    User.current_user, @request.session[:user] = nil
    get :edit, :permalink => messages(:haiti_message).permalink
    assert_response :redirect
    get :show, :permalink => messages(:haiti_message).permalink
    assert_response :redirect
    
    # In a homebase but not logged in...
    Homebase.current_homebase = Homebase.find(1)
    User.current_user, @request.session[:user] = nil
    get :edit, :permalink => messages(:haiti_message).permalink
    assert_response :redirect 
    post :edit, :permalink => messages(:haiti_message).permalink, :project => {:name => "Message 1 tried to be modified by an unauthorized user"}
    assert_response :redirect
    get :show, :permalink => messages(:haiti_message).permalink
    assert_response :redirect
    
    
  end
  
  def test_delete
    simulate_login
    
    xhr :post, :delete, :permalink => messages(:haiti_message).permalink  
    assert_equal "Message deleted", @response.flash[:notice]
    assert_response :redirect
    assert_redirected_to :action => "index"
  end

  def test_can_associate_message_with_received_projects
    # Post a new message
    # Associate it with a project from Project.received_projects
  end
  
    
  def test_list_received_messages    
  end
    

  
end


