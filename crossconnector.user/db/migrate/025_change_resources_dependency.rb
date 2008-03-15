class ChangeResourcesDependency < ActiveRecord::Migration
  def self.up
    add_column "resources", "project_id", :integer
    add_column "projects", "resources_count", :integer, :default => 0
  end

  def self.down
    remove_column "resources", "project_id"
    remove_column "projects", "resources_count"
  end
end
