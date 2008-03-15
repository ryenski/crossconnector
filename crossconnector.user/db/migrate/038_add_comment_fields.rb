class AddCommentFields < ActiveRecord::Migration
  def self.up
    add_column "comments", "user_agent", :string
    add_column "comments", "referer", :string
  end

  def self.down
    remove_column "comments", "user_agent"
    remove_column "comments", "referer"
  end
end
