require File.dirname(__FILE__) + '/../test_helper'

class AccessLogTest < Test::Unit::TestCase
  fixtures :access_logs

  # Replace this with your real tests.
  def test_truth
    assert_kind_of AccessLog, access_logs(:first)
  end
end
