require File.dirname(__FILE__) + '/../test_helper'
require 'theme_controller'

# Re-raise errors caught by the controller.
class ThemeController; def rescue_action(e) raise e end; end

class ThemeControllerTest < Test::Unit::TestCase
  def setup
    @controller = ThemeController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
