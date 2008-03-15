ENV["RAILS_ENV"] = "test"
require File.expand_path(File.dirname(__FILE__) + "/../config/environment")
require 'test_help'

class Test::Unit::TestCase 
  # Turn off transactional fixtures if you're working with MyISAM tables in MySQL
  self.use_transactional_fixtures = true
  
  # Instantiated fixtures are slow, but give you @david where you otherwise would need people(:david)
  self.use_instantiated_fixtures  = false

  # Add more helper methods to be used by all tests here...
  
  def setup_homebases
    # Insert the homebase.created_by values.
    # Since the homebase referrs to the user, and the user referrs to the homebase, we have a circular reference. 
    # Created_by can't be set at the time of insert because the user doesn't exist yet. 
    Homebase.find(1).update_attribute(:created_by, 1001)
    Homebase.find(2).update_attribute(:created_by, 1003)
    Homebase.find(3).update_attribute(:created_by, 1004)
    Homebase.find(5).update_attribute(:created_by, 1006)
    
    @request.host = "haiti.crossconnector.com" if @request
    
  end
  
  def assert_can_see_protected_object(user, object, can_see=true)
    
    Homebase.current_homebase = Homebase.find(user.homebase_id)
    User.current_user = User.find_by_email_and_homebase_id(user.email, Homebase.current_homebase.id)

    type = object.class
    if can_see == false
      assert_raise(ActiveRecord::RecordNotFound) { type.find_protected(object.id) } 
    else
      assert_nothing_raised(ActiveRecord::RecordNotFound) { type.find_protected(object.id) }
    end
  end
  
  def setup_session(user_id)
    @request.session[:user] = User.find(user_id)
    User.current_user = @request.session[:user]    
    Homebase.current_homebase = @request.session[:user].homebase
  end
  
  
  
  def login(username='ryan', password='test', subdomain='haiti', expect_to_fail=false)
    # Homebase.current_homebase = Homebase.find_by_subdomain(subdomain)
    @request.host = "#{subdomain}.crossconnector.com"
    @request.session[:return_to] = "/bogus/location"
    get :login
    post :login, :user => {:username => username, :password => password}
    User.current_user = session[:user]
    case expect_to_fail
      when false
        #assert_response :redirect
        assert_redirected_to "/bogus/location"
        assert_not_nil flash[:notice].match(/Login successful. Welcome to your homebase!/)
        
        assert_equal session[:user], User.current_user
        assert_not_nil session[:user].homebase.subscription.status
        assert_not_nil session[:user].login_counter
        assert_not_nil session[:user].login_counter
        assert session[:user].logged_in_at < Time.now + 1.minute
      when true
        assert_response :success
        assert_nil session[:user]
        assert_nil User.current_user
    end
    
  end

  # Simulates a login  
  def simulate_login(user="ryan@example.com", homebase="haiti")
    Homebase.current_homebase = Homebase.find_by_subdomain(homebase)
    User.current_user = User.find_by_email_and_homebase_id(user, Homebase.current_homebase.id)
    
    @request.session[:user] = User.current_user
    
    @homebase = Homebase.current_homebase
    @user = User.current_user
  end
  
  def logout
    User.current_user = nil
    @request.session[:user] = nil 
  end
  
  def assert_xml(xml)
    assert_nothing_raised do
      assert REXML::Document.new(xml)
    end
  end
  
end