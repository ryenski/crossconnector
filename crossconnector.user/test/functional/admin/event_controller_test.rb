require File.dirname(__FILE__) + '/../../test_helper'
require 'admin/event_controller'

# Re-raise errors caught by the controller.
class Admin::EventController; def rescue_action(e) raise e end; end

class Admin::EventControllerTest < Test::Unit::TestCase
  fixtures :subscription_plans, :homebases, :users, :projects, :events
  
  def setup
    @controller = Admin::EventController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    
    setup_homebases
  end

  def test_create
    simulate_login
    
    project = projects(:haiti_project)
    assert_equal 2, project.events.count
    
    xhr :post, :new, :event => { :name => "New Event", :project_id => project.id, :start_date => Time.now + 1.week }
    assert_nil flash[:error]
    
    assert_equal 3, assigns(:event).project.events.count  
    
    project = Project.find(project.id)
    assert_equal 3, project.events.count
  end
  
  def test_destroy
    simulate_login
    
    project = projects(:haiti_project)
    assert_equal 2, project.events.count
    
    xhr :post, :delete, :id => project.events.first.id
    project.reload
    assert_equal 1, project.events.count
    
    xhr :post, :delete, :id => project.events.first.id
    project.reload
    assert_equal 0, project.events.count
    
  end
  
end
