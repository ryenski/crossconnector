require File.dirname(__FILE__) + '/../test_helper'

class LeaderTest < Test::Unit::TestCase
  fixtures :subscription_plans, :homebases, :users

  def setup
    setup_homebases
    @leader = User.find(1002)
  end

  # Replace this with your real tests.
  def test_truth
    assert_kind_of Leader, @leader
  end
end
