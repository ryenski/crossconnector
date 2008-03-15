require File.dirname(__FILE__) + '/../test_helper'

class HomebaseTest < Test::Unit::TestCase
  fixtures :subscription_plans, :homebases, :users

  def setup
    #setup_homebases
    
  end

  
  def test_fixtures
    
    assert_equal "Ryan Heneise", users(:ryan).name.to_s
    
    @homebase = Homebase.find(4)
    assert_kind_of Homebase,  @homebase
    #assert_equal "Haiti Connection", @homebase.name
    
    #assert_equal @homebase, homebases(:homebase_four)
  end
  
  def test_mixed_case
    Homebase.create(:name => "My Homebase", :subdomain => "MixEdCase")
    assert_not_nil Homebase.find_by_subdomain("mixedcase")
    #assert_not_nil Homebase.find_by_subdomain("MixEdCase")
    
  end
  
  def test_update_subscription_plan
    #setup
    #@ryan.update_subscription_plan(3)
    #@ryan.save
    #assert_equal "Missionary", @ryan.subscription_plan.name
  end
  
  def test_projects_for_homebase
    @homebase = Homebase.find(1)
    assert_equal 4, @homebase.projects.count
    assert_equal 1, @homebase.archived_projects.count
    assert_equal 3, @homebase.public_projects.count
    assert_equal 1, @homebase.public_archived_projects.count
  end
  
  def test_messages_for_homebase
    @homebase = Homebase.find(1)
    assert_equal 18, @homebase.messages.count
    assert_equal 16, @homebase.public_messages.count
  end
  
  def test_files_for_homebase
    
  end
  
  def test_fix_url
    h = Homebase.create(:name => "New homebase", :subdomain => "my_homebase", :website => "www.example.com")
    assert_equal "http://www.example.com", h.website
  end
  
end
