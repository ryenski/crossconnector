require File.dirname(__FILE__) + '/../test_helper'

class ScreenshotTest < Test::Unit::TestCase
  fixtures :screenshots

  # Replace this with your real tests.
  def test_truth
    assert_kind_of Screenshot, screenshots(:first)
  end
end
