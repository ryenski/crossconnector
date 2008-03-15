class AddLeaderOptions < ActiveRecord::Migration
  def self.up
    User.transaction do
      add_column "users", "can_edit_leaders", :integer, :default => 1
      change_column "users", "can_edit_projects", :integer, :default => 1
      change_column "users", "can_edit_messages", :integer, :default => 1
      change_column "users", "can_edit_addresses", :integer, :default => 1
      change_column "users", "can_edit_files", :integer, :default => 1
    end
  end

  def self.down
    
    User.transaction do
      remove_column "users", "can_edit_leaders"
      change_column "users", "can_edit_projects", :integer, :default => 0
      change_column "users", "can_edit_messages", :integer, :default => 0
      change_column "users", "can_edit_addresses", :integer, :default => 0
      change_column "users", "can_edit_files", :integer, :default => 0
    end
    
  end
end
