require File.dirname(__FILE__) + '/../test_helper'

class AddressTest < Test::Unit::TestCase
  fixtures :subscription_plans, :homebases, :users, :groups, :addresses, :addresses_groups

  def setup
    # setup_homebases
  end

  def test_addresses_for_haiti
    @find_addresses_for_haiti = Address.find_all_by_created_by(1001)
    assert_equal 6, @find_addresses_for_haiti.size
  end
  
  def test_toggle_address_in_group
    before = groups(:group_one).addresses.size
    Address.toggle_address_in_group(4, groups(:group_one).id, :add)
    assert_equal (before + 1), Group.find(1).addresses.size
    
    Address.toggle_address_in_group(4, groups(:group_one).id, :delete)
    assert_equal (before), Group.find(1).addresses.size
    
  end
  
  
end
