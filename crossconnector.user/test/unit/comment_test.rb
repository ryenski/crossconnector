require File.dirname(__FILE__) + '/../test_helper'

class CommentTest < Test::Unit::TestCase
  fixtures :subscription_plans, :homebases, :users, :messages, :comments

  def setup
    setup_homebases
    @comment = Comment.find(1)
  end

  # Replace this with your real tests.
  def test_truth
    assert_kind_of Comment,  @comment
  end
end
