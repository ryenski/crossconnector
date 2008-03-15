require File.dirname(__FILE__) + '/../../test_helper'
require 'admin/homebase_controller'

# Re-raise errors caught by the controller.
class Admin::HomebaseController; def rescue_action(e) raise e end; end

class Admin::HomebaseControllerTest < Test::Unit::TestCase
  
  fixtures :subscription_plans, :homebases, :users, :subscription_plan_priveleges, :subscription_plan_items, :subscriptions
  
  def setup
    @controller = Admin::HomebaseController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    
    setup_homebases
  end

  def test_not_logged_in
    Homebase.current_homebase = Homebase.find(1)
    User.current_user = nil
    get :index
    #assert_redirected_to :controller => "account", :action => "login"
    assert_redirected_to @request.protocol + @request.host + "/admin/login"
  end
  
  
  def test_logged_in_with_different_homebase
    User.current_user = User.find(1001)
    Homebase.current_homebase = Homebase.find(2)
    get :index
    #assert_redirected_to :controller => "account", :action => "login"
    assert_redirected_to @request.protocol + @request.host + "/admin/login"
  end
  
  def test_logged_in_good
    simulate_login
    get :index
    assert_response :success
  end
  
  def test_logged_in_with_lapsed_account
  end
  
  def test_logged_in_with_pending_account    
  end
  
  def test_routing_and_pagination
    opts = {:controller => "admin/message", :action => "index"}
    assert_routing("/admin/messages", opts)
    
    opts = {:controller => "admin/message", :action => "index", :page => "2"}
    assert_routing("/admin/messages/page/2", opts)


    opts = {:controller => "admin/project", :action => "index"}
    assert_routing("/admin/projects", opts)
    
    opts = {:controller => "admin/project", :action => "index", :page => "2"}
    assert_routing("/admin/projects/page/2", opts)
    
    
    opts = {:controller => "admin/file", :action => "index"}
    assert_routing("/admin/files", opts)
    
    opts = {:controller => "admin/file", :action => "index", :page => "2"}
    assert_routing("/admin/files/page/2", opts)
  end
  
  
end
