require File.dirname(__FILE__) + '/../../test_helper'
require 'admin/account_controller'

# Re-raise errors caught by the controller.
class Admin::AccountController; def rescue_action(e) raise e end; end

class Admin::AccountControllerTest < Test::Unit::TestCase
  
  fixtures :subscription_plans, :homebases, :users, :subscription_plan_priveleges, :subscription_plan_items, :subscriptions, :invoices
  
  def setup
    @controller = Admin::AccountController.new
    @request, @response = ActionController::TestRequest.new, ActionController::TestResponse.new
    setup_homebases
    #@request.host = "haiti.crossconnector.com"
  end

  
  def test_paid_login
    login(users(:ryan).email, "test", "haiti")
    assert_equal "paid", User.current_user.homebase.subscription.status
    
    assert_not_nil assigns(:homebase).subscription
    assert_not_nil assigns(:homebase).subscription.next_billing_date
    
    get :index  
    assert_response :success
    logout
  end
  
  def test_trial_login
    # @request.host = "covinavineyard.crossconnector.com"
    login(users(:alan).email, "atest", "covinavineyard")
    assert_equal "trial", User.current_user.homebase.subscription.status
    logout
  end
  
  def test_free_login
    @request.host = "new_homebase.crossconnector.com"
    
    login(users(:new_user).email, "foobar", "new_homebase")
    assert_equal "free", User.current_user.homebase.subscription.status
    logout
  end

  def test_paid_login
    login("haiti_leader", "Leader", "haiti", expect_to_fail=false)
    assert_equal "paid", User.current_user.homebase.subscription.status
    logout
  end
  
    # Bad subscription status
    #login(users(:homebase_four_user).email, "test", "four", expect_to_fail=true)
    
  def test_failed_logins  
    login("bob", "test", "haiti", expect_to_fail=true)
    login("ryan", "tester", "haiti", expect_to_fail=true)
    login("ryan", "test", "different", expect_to_fail=true)
  end
  
  def test_leader_login
    login("haiti_leader", "Leader", "haiti", expect_to_fail=false)
    get :index  
    assert_response :success
  end
  
  # An account where the free trial has ended
  def test_login_with_free_trial_ended
    @request.host = "different.crossconnector.com"
    login(users(:different_ryan).email, "different", "different")
    assert_equal "free", User.current_user.homebase.subscription.status
    assert_not_nil flash[:notice].match(/your account has automatically been downgraded to the Free version/)
    
    logout    
  end
  
  # An account that had credit card invoice, but we were unable to continue processing the card
  def test_login_with_lapsed_account
    
  end
  
  def test_leader_cant_see_protected_actions
    # login("haiti_leader", "Leader", "haiti", expect_to_fail=false)
    simulate_login("haiti_leader@example.com", "haiti")
    get :profile  
    assert_response :redirect
    
    #get :new
    #assert_response :redirect
  end
  
  def test_login_with_token
    
    # This part happens in SignupController in the secure application
    p = SubscriptionPlan.find_by_name("Pro")
    u = User.create(:name => "Token User", :email => "token@example.com", :password => "token", :password_confirmation => "token", :terms => "1")
    h = Homebase.create(:subdomain => "token_subdomain", :name => "Token Subdomain")
    s = Subscription.create(:homebase_id => h.id, :name => u.name, :email => u.email, :terms => "1", :price => p.price, :subscription_plan_id => p.id, :trial_ends_at => Time.now+30.days)
    u.update_attributes(:homebase_id => h.id)
    h.update_attributes(:created_by => u.id)
    
    assert u.reload
    assert h.reload
    assert s.reload
    
    Homebase.current_homebase = Homebase.find_by_subdomain(h.subdomain)
    @request.host = "#{h.subdomain}.crossconnector.com"
    get :login_with_token, :t => u.security_token
    assert_redirected_to :action => :do_login_with_token, :token => u.security_token
    
    get :do_login_with_token, :token => u.security_token
    assert_equal u, session[:user]
    assert_equal u, User.current_user
    assert_equal h, Homebase.current_homebase
    assert_redirected_to "/admin"
    assert_equal flash[:notice], "Signup successful. Welcome to your new CrossConnector homebase!"
    
    assert_equal "Pro", Homebase.current_homebase.subscription.plan.name
    assert_equal "trial", Homebase.current_homebase.subscription.status
    assert_equal (Time.now + 30.days).strftime("%D"), Homebase.current_homebase.subscription.trial_ends_at.strftime("%D")
    
    u = User.find(u.id)
    assert_nil u.security_token
  end
  
  def test_bad_login_with_token
    # Wrong subdomain...
    Homebase.current_homebase = Homebase.find_by_subdomain("haiti")
    get :do_login_with_token, :token => users(:new_user).security_token
    assert_redirected_to :action => "login"
    
    # No token...
    Homebase.current_homebase = Homebase.find_by_subdomain("new_homebase")
    get :do_login_with_token
    assert_redirected_to :action => "login"
    
    # Blank token...
    Homebase.current_homebase = Homebase.find_by_subdomain("new_homebase")
    get :do_login_with_token, :t => ""
    assert_redirected_to :action => "login"
    
    # Messed up token...
    Homebase.current_homebase = Homebase.find_by_subdomain("new_homebase")
    get :do_login_with_token, :t => "foofoofoo"
    assert_redirected_to :action => "login"
    
    # Expired token...
    Homebase.current_homebase = Homebase.find_by_subdomain("new_homebase")
    User.find(users(:new_user).id).update_attribute(:token_expiry, Time.now - 1.minute)
    get :do_login_with_token, :t => users(:new_user).security_token
    assert_redirected_to :action => "login"
    
  end
  
  def test_logout
    login("ryan", "test", "haiti", expect_to_fail=false)
    post :logout
    
    assert_nil User.current_user
    assert_nil session[:user]
  end

  def test_change_password
    login("ryan", "test", "haiti")
    
    # Pass..
    post :password, :user => { :password => "new_password", :password_confirmation => "new_password" }
    u = User.find(1001)
    assert_equal "new_password", u.decrypted_password
    #assert_equal User.salted_password(u.salt, User.hashed("new_password")), u.salted_password
    
  
    # Fail...
    post :password, :user => { :password => "good_password_but", :password_confirmation => "bad_confirmation" }
    assert_equal "new_password", u.decrypted_password
    #assert_redirected_to :controller => "/admin/account", :action => "password"
    #assert_equal "An error occurred, and your password was not changed", @response.flash[:notice]
    
  end
  
  def test_change_leader_password
    login(users(:haiti_leader).email, "Leader", "haiti", expect_to_fail=false)
    
    post :password, :user  => {:password => "new_password", :password_confirmation => "new_password" }
    assert_equal "Password changed successfully", flash[:notice]
    
    h = Homebase.find(1)
    assert_equal 1001, h.created_by.id
    
  end
  
  def test_update_profile
    login
    post :profile, :homebase => { :name => "My new organization" }
    homebase = Homebase.find(1)
    
    assert_equal "My new organization", homebase.name
  end
  
  def test_update_personal_info
    login("ryan", "test", "haiti")
    u = User.find(1001)
    assert_equal "Ryan Heneise", u.name.to_s
    post :your_info, :user => { :name => "My new Name" }
    u = User.find(1001)
    assert_equal "My new Name", u.name.to_s
    # make sure password did not change
    assert_equal ActiveRecord::PasswordSystem.encrypt("test", u.salt), u.salted_password
  end
  
  
  def test_delete_user
    # should delete the user, their homebase, and all their associated stuff
  end
  
  
  
  def test_forgot_password
    Homebase.current_homebase = Homebase.find(1)
    User.current_user#, session[:user] = nil
    get :forgot_password
    assert_response :success
    
    post :forgot_password, :user => {:email => users(:ryan).email}
    assert_response :success
    
  end
  
  def test_edit_my_info
    login("ryan", "test", "haiti")
    assert_response :redirect
    
    get :your_info
    assert_response :success
    
    # Conflict with email - 1 Errors
    post :your_info, :user => {:email => "haiti_leader@example.com"}
    assert_equal 1, assigns(:user).errors.count
    
    # Conflict with email and username - 2 Errors
    post :your_info, :user => {:email => "haiti_leader@example.com"}
    assert_equal 1, assigns(:user).errors.count
    
    # No conflict, even though the email belongs to someone in another homebase
    post :your_info, :user => {:email => "different_ryan@example.com"}
    assert_equal 0, assigns(:user).errors.count
  end

  
end
