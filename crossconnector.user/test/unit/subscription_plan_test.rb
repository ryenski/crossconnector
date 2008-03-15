require File.dirname(__FILE__) + '/../test_helper'

class SubscriptionPlanTest < Test::Unit::TestCase
  fixtures :subscription_plans, :subscription_plan_priveleges, :subscription_plan_items

  def setup
    @subscription_plan = SubscriptionPlan.find(1)
  end

  # Replace this with your real tests.
  def test_truth
    assert_kind_of SubscriptionPlan,  @subscription_plan
  end
  
  def test_plan_projects_limit
    # Free plan should have a projects limit of 1
    #assert_equal 1.to_s, @free_subscription_plan.subscription_plan_priveleges.find(1).plan_limit
    # Megachurch should have limit of 50
    #assert_equal 50.to_s, @megachurch_subscription_plan.subscription_plan_priveleges.find(1).plan_limit
  end
  
  def test_plan_storage_limit
    # Free plan should have a projects limit of 10
    #assert_equal 10.to_s, @free_subscription_plan.subscription_plan_priveleges.find(2).plan_limit
    # Megachurch should have limit of 50
    #assert_equal 500.to_s, @megachurch_subscription_plan.subscription_plan_priveleges.find(2).plan_limit
  end
  
end
