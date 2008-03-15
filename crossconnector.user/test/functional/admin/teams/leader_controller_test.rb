require File.dirname(__FILE__) + '/../../../test_helper'
require 'admin/teams/leader_controller'

# Re-raise errors caught by the controller.
class Admin::Teams::LeaderController; def rescue_action(e) raise e end; end

class Admin::Teams::LeaderControllerTest < Test::Unit::TestCase

  fixtures :subscription_plans, :homebases, :users, :subscription_plan_priveleges, :subscription_plan_items, :subscriptions, :invoices

  def setup
    @controller = Admin::Teams::LeaderController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    
    setup_homebases
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end
  
  
  
  def test_create_leader
    simulate_login
    post :new, :leader => {:email => "new_guy2@example.com", :name => "New Guy", :password => "test", :password_confirmation => "test"}
    assert_equal "Leader saved", flash[:notice]
    
    assert_equal "new_guy2@example.com", assigns(:leader).email
    assert_response :redirect
    assert_redirected_to :action => "index"
    #e = User.find_by_email("new_guy2@example.com")
    #assert_not_nil e
    #assert_equal Leader, e.class
  end
  
  def test_create_leader_with_same_login

    simulate_login
    post :new, :leader => {:email => "ryan@example.com", :password => "test", :password_confirmation => "test"}
    assert_response 200 
    assert_not_nil flash[:notice]
    assert_not_nil flash[:notice].match(/There was an error saving this leader./)
    #assert_raise(ActiveRecord::RecordNotFound) { User.find(users(:haiti_leader).id) }
    # Success would mean that the leader was NOT created
    # assert_nil User.find_by_email("dup_ryan@example.com")
    
  end
  
  def test_edit_leader
    #login("ryan", "test", "haiti")
    simulate_login("ryan@example.com", "haiti")
    assert_not_nil Homebase.current_homebase
    assert_not_nil User.current_user
    
    post :edit, :id => users(:haiti_leader).id, :leader => {:name => "new_name", :email => "leader@example.com", :password => "new_password", :password_confirmation => "new_password"}
    assert_response :success
    assert_equal "Leader saved", flash[:notice]
    leader = User.find(users(:haiti_leader).id)
    assert_equal "new_name", leader.name
    assert_equal "new_password", leader.decrypted_password
  end
  
  
  def test_delete_leader
    simulate_login("ryan@example.com", "haiti")
    post :delete, :id => users(:haiti_leader).id
    assert_redirected_to :action => "index"
    assert_equal "Leader deleted", flash.now[:notice]
    @leader = User.find(users(:haiti_leader).id)
    assert_equal 1, @leader.deleted
    assert_nil @leader.username
    assert_nil @leader.password
  end
end
