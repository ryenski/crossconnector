require File.dirname(__FILE__) + '/../test_helper'

class UserTest < Test::Unit::TestCase
  fixtures :subscription_plans, :homebases, :users, :messages

  def setup
    setup_homebases
    
    Homebase.current_homebase = Homebase.find(1)
  end
  
  def test_truth
    assert_kind_of User, users(:ryan)
  end
  
  def test_create_user
    assert u = User.create(:name => "New User", :password => "foobar", :email => "newuser@example.com", :terms => 1)
    assert h = Homebase.create(:name => "New Homebase", :subdomain => "new_subdomain", :created_by => u.id)
    assert u.update_attribute(:homebase_id, h.id)
    
    assert_not_nil u.salted_password
    assert_equal "foobar", u.decrypted_password
  end
  
  
  def test_auth
    assert_equal users(:ryan), User.authenticate("ryan", "test")
    login_counter = User.find(users(:ryan).id).login_counter
    ryan = User.authenticate("ryan", "test")
    assert_equal (login_counter + 1), ryan.login_counter
    
    assert_equal users(:ryan), User.authenticate("ryan@example.com", "test")
    assert_nil User.authenticate("ryan@haiti.com", "notmypassword")
    
    Homebase.current_homebase = Homebase.find(2)
    assert_nil User.authenticate("ryan", "test")

  end
  
  def test_right_number_of_messages
    @user = User.find(1001)
    assert_equal 18, @user.messages.count
    assert_equal 1, @user.draft_messages.count
     
  end
  
  def test_change_password
    
    Homebase.current_homebase = Homebase.find(1)
    @user = User.find(1001)
    @user.password = "newpassword"
    @user.save
    
    @user = User.find(1001)
    assert_not_nil @user
    assert_equal "newpassword", @user.decrypted_password
    
    @user = User.authenticate("ryan", "newpassword")
    assert_not_nil @user
    
    #@user.password = "this_password_is_way_too_longthis_password_is_way_too_longthis_password_is_way_too_longthis_password_is_way_too_longthis_password_is_way_too_longthis_password_is_way_too_longthis_password_is_way_too_longthis_password_is_way_too_longthis_password_is_way_too_longthis_password_is_way_too_longthis_password_is_way_too_longthis_password_is_way_too_long"
    #assert_equal false, @user.save
    
    #@user.password = "a"
    #assert_equal false, @user.save
    
    @user.password = "ea580216cf6aa780704c007c90c1fb704006a7b8" # I like to hash my passwords
    assert_equal true, @user.save
    
    #@user.password = "seemsOk"
    #@user.password_confirmation = "shouldn'tsave"
    #assert_equal false, @user.save
    
  end
  
  
  def test_create_new_user_with_same_email_in_different_homebase
    # Email and username should be unique in the context of a homebase. 
    # Should be able to have two users with the same username but different homebases
    Homebase.current_homebase = Homebase.find(2)
    User.current_user = User.find(1001)
    @new_ryan = User.new
    @new_ryan.name = "Ryan Heneise"
    @new_ryan.username = "ryan"
    @new_ryan.email = "ryan@heneise.com"
    @new_ryan.password = "new_ryans_password"
    #@new_ryan.homebase_subdomain = Homebase.current_homebase.subdomain
    @new_ryan.save
    assert_equal @new_ryan, User.authenticate("ryan", "new_ryans_password")
  end
  
  
  

  
  def test_leader_login
    Homebase.current_homebase = Homebase.find(2)
    assert_nil User.authenticate("leader", "Leader")
    
    Homebase.current_homebase = Homebase.find(1)    
    assert_equal @leader, User.authenticate("leader", "Leader")
    @leader = User.find(1002)
    assert_equal Leader, @leader.class
  end
  
  def test_generate_security_token
    @user = User.find(1001)
    assert_nil @user.security_token
    @user.generate_security_token(1)
    assert_not_nil @user.security_token
    @user2 = User.find(1001)
    assert_not_nil @user2.token_expiry
  end
  
  def test_authenticate_with_token
    
    # Pass...
    Homebase.current_homebase = Homebase.find(1)
    assert user = User.find(1001)
    assert_nil user.security_token
    assert user.generate_security_token(1)
    
    logged_in = User.authenticate_with_token(user.security_token)
    assert_not_nil logged_in
    assert_equal nil, logged_in.token_expiry
    assert_equal nil, logged_in.security_token
    
    # Fail...
    Homebase.current_homebase = Homebase.find(1)  
    @user = User.find(1003)
    @user.generate_security_token(1)
    @logged_in = User.authenticate_with_token(@user.security_token)
    assert_nil @logged_in
    
  end
  
  def test_soft_delete
    # Marks the user and homebase as deleted. 
    
  end
  
  def test_permanent_delete
    # should cascade and delete all their things, creating all kinds of havoc
    # User.delete(1001)
    # assert_equal false, User.find(1001)
  end
  
  
  def test_leaders_cant_change_subscription
  end
  
  def test_create_leader
    Homebase.current_homebase = Homebase.find(1) 
    User.current_user = User.find(1001)
    Leader.delete_all
    @ed = Leader.new(:name => "Ed Itor", :username => "ed", :email => "leader@example.com")
    @ed.password = "leader_pass"
    
    assert_equal true, @ed.save
    assert_equal @ed, User.authenticate("ed", "leader_pass")
    
  end
  
end
