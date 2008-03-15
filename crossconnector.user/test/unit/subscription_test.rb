require File.dirname(__FILE__) + '/../test_helper'

class SubscriptionTest < Test::Unit::TestCase
  fixtures :subscription_plans, :subscription_plan_priveleges, :subscription_plan_items, :homebases, :users, :subscriptions, :invoices
  
  def setup
    setup_homebases
  end
  
  def test_paid_status
    h = Homebase.find(1)
    assert_equal "paid", h.subscription.status
  end
  
  def test_free_status
    h = Homebase.find(4)
    assert_equal "free", h.subscription.status    
  end
  
  def test_trial_status
    h = Homebase.find(2)
    assert_equal "trial", h.subscription.status 
  end
  
  def test_lapsed_status
    h = Homebase.find(3)
    assert_equal "lapsed", h.subscription.status
  end
  
end
