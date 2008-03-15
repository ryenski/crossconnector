require File.dirname(__FILE__) + '/../test_helper'
require 'feed_controller'

# Re-raise errors caught by the controller.
class FeedController; def rescue_action(e) raise e end; end

class FeedControllerTest < Test::Unit::TestCase
  
  fixtures :subscription_plans, :homebases, :users, :projects, :messages, :resources, :tags, :tags_messages, :tags_projects, :tags_resources
  
  def setup
    @controller = FeedController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    setup_homebases
  end

  
  def test_homebase_feed
    
    get :rss, :type => "homebase"
    assert_response :success
    assert_xml @response.body
    
    #assert_equal "Foo", @response.body
    
  end
  
end
