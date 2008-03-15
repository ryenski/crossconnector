require File.dirname(__FILE__) + '/../test_helper'

class AlertTest < Test::Unit::TestCase
  fixtures :alerts

  # Replace this with your real tests.
  def test_truth
    assert_kind_of Alert, alerts(:first_alert)
  end
end
