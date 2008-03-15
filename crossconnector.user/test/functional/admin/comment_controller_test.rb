require File.dirname(__FILE__) + '/../../test_helper'
require 'admin/comment_controller'

class ActionController::TestRequest
  attr_accessor :user_agent
  attr_accessor :referer
end

# Re-raise errors caught by the controller.
class Admin::CommentController; def rescue_action(e) raise e end; end

class Admin::CommentControllerTest < Test::Unit::TestCase
  
  fixtures :subscription_plans, :homebases, :users, :messages, :comments
  
  def setup
    @controller = Admin::CommentController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    
    setup_homebases
    
    @request.user_agent = "Test"
    @request.referer = ""
    
  end
  
  def test_create_comment
    simulate_login
    message = messages(:haiti_message)
    assert_equal 2, message.comments.count
    xhr :post, :new, :comment => {:body => "new comment", :name => "New Commentor", :email => "commentor@example.com", :message_id => message.id}
    assert_response :success
    assert_equal [], assigns(:comment).errors.full_messages
    assert_equal 3, assigns(:comment).message.comments.count
  end
  
  def test_delete_comment
    simulate_login
    message = messages(:haiti_message)
    assert_equal 2, message.comments.count
    xhr :post, :delete, :id => comments(:first_comment_on_haiti_message).id
    assert_response :success
    message.reload
    assert_equal 1, message.comments.count
  end
  
  
end
