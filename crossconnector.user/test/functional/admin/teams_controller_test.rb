require File.dirname(__FILE__) + '/../../test_helper'
require 'admin/teams_controller'

# Re-raise errors caught by the controller.
class Admin::TeamsController; def rescue_action(e) raise e end; end

class Admin::TeamsControllerTest < Test::Unit::TestCase
  
  fixtures :users, :addresses, :groups, :addresses_groups, :homebases
  
  def setup
    @controller = Admin::TeamsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    
    setup_homebases
    
    setup_session(1001)
  end

  def test_add_group
    post :add_group, :add_group => {:name => "New Group"}
    @group = Group.find_by_name("New Group")

    assert_not_nil @group
    assert_equal "New Group", @group.name    
  end
  
  def test_get_address
    get :get_address_detail, :id => addresses(:haiti_address_bethany).id
    assert_response :success
    
  end
  
  def test_add_first_address
    #setup_session(users(:new_user).id)
    @request.host = "#{homebases(:new_homebase).subdomain}.crossconnector.com"
    simulate_login(users(:new_user).email, homebases(:new_homebase).subdomain)
    
    post :add_address, :add_address => {:email => "first_email@address.com"}
    #assert_response :success
    #breakpoint
    address = Homebase.current_homebase.addresses.find_by_email("first_email@address.com")

    assert_not_nil address
    assert_equal "first_email@address.com", address.email
    
  end

  
  def test_delete_group
    post :delete_group, :id => groups(:group_one).id
    assert_template "_addressbook"
    assert_response :success
  end
  
  def test_delete_group_failure
    post :delete_group, :id => 84564
    assert_response :success
  end
  
  def test_edit_group    
  end
  
  def test_add_address
    post :add_address, :add_address => {:email => "new@address.com"}
    @address = Address.find_by_email("new@address.com")

    assert_not_nil @address
    assert_equal "new@address.com", @address.email    
  end
  
  def test_delete_address
  end
  
  def test_edit_address
  end




  def test_toggle_address_group
    # "checked" => "true"
    # "group_id" => "3"
    # "address_id" => "4"
    # Parameters: 
    #  {"checked"=>"false", "action"=>"toggle_address_group", "group_id"=>"3", "address_id"=>"1", "controller"=>"addressbook"}

    @before_addresses = Address.find(addresses(:haiti_address_not_in_group).id).groups.size
    @before_groups    = Group.find(groups(:group_two).id).addresses.size

    # Add
    post :toggle_address_in_group, :group_id => groups(:group_two).id, :address_id => addresses(:haiti_address_not_in_group).id, :checked => "true"
    @after_address = Address.find(addresses(:haiti_address_not_in_group).id)
    @after_groups  = Group.find(groups(:group_two).id)
    
    assert_response :success
    assert_equal (@before_addresses + 1), @after_address.groups.size
    assert_equal (@before_groups + 1), @after_groups.addresses.size
    
    # Remove
    post :toggle_address_in_group, :group_id => groups(:group_two).id, :address_id => addresses(:haiti_address_not_in_group).id, :checked => "false"
    @after_address = Address.find(addresses(:haiti_address_not_in_group).id)
    @after_groups  = Group.find(groups(:group_two).id)
    
    assert_response :success
    assert_equal (@before_addresses), @after_address.groups.size
    assert_equal (@before_groups), @after_groups.addresses.size 
  end
  
  def test_add_existing_address_to_group
    @request.session[:last_group] = groups(:group_one).id
    post :add_address, :add_address => {:email => addresses(:existing_address_not_in_group).email}
    a = Address.find(addresses(:existing_address_not_in_group).id)
    assert_equal 1, a.groups.size

    @request.session[:last_group] = groups(:group_two).id
    post :add_address, :add_address => {:email => addresses(:existing_address_not_in_group).email}
    a.reload
    assert_equal 2, a.groups.size
  end
  
  def test_add_someone_to_group_with_project
    # Adding someone to the group after the group has already been assigned to a project... 
    
  end
end
