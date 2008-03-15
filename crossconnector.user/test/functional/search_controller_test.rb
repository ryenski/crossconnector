require File.dirname(__FILE__) + '/../test_helper'
require 'search_controller'

# Re-raise errors caught by the controller.
class SearchController; def rescue_action(e) raise e end; end

class SearchControllerTest < Test::Unit::TestCase
  
  fixtures :subscription_plans, :homebases, :users, :messages, :comments, :projects, :events
  
  def setup
    @controller = SearchController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    setup_homebases
    
    #@request.host = "haiti.crossconnector.com"
    
  end

  # Replace this with your real tests.
  def test_search
    simulate_login
    post :search, :query => "haiti"
    
    assert_response :success
    assert assigns(:query)
    assert_equal 4, assigns(:results).size
    
  end
  
  def test_search_with_multiple_words
    simulate_login
    post :search, :query => "an old archived"
    
    assert_response :success
    assert assigns(:query)
    assert_equal 1, assigns(:results).size
  end
  
end
