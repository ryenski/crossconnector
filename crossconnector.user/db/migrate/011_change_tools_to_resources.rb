class ChangeToolsToResources < ActiveRecord::Migration
  def self.up
    STDERR.puts "Migrating to version 11..."
    
    Homebase.transaction do
      rename_column "access_logs", "tool_id", "resource_id"
      rename_column "addresses_tools", "tool_id", "resource_id"
      rename_column "groups_tools", "tool_id", "resource_id"
      rename_column "homebases", "tools_count", "resources_count"
      rename_column "messages_tools", "tool_id", "resource_id"
      rename_column "projects_tools", "tool_id", "resource_id"
      rename_column "tags_tools", "tool_id", "resource_id"
      
      rename_table "tools", "resources"
      rename_table "addresses_tools", "addresses_resources"
      rename_table "groups_tools", "groups_resources"
      rename_table "messages_tools", "messages_resources"
      rename_table "projects_tools", "projects_resources"
      rename_table "tags_tools", "tags_resources" 
    end
    
    STDERR.puts "\ndone."
  end

  def self.down
    STDERR.puts "Migrating down from version 11..."
    
    Homebase.transaction do
      rename_table "resources", "tools"
      rename_table "addresses_resources", "addresses_tools"
      rename_table "groups_resources", "groups_tools"
      rename_table "messages_resources", "messages_tools"
      rename_table "projects_resources", "projects_tools"
      rename_table "tags_resources", "tags_tools"
      
      rename_column "access_logs", "resource_id", "tool_id"
      rename_column "addresses_tools", "resource_id", "tool_id"
      rename_column "groups_tools", "resource_id", "tool_id"
      rename_column "homebases", "resources_count", "tools_count"
      rename_column "messages_tools", "resource_id", "tool_id"
      rename_column "projects_tools", "resource_id", "tool_id"
      rename_column "tags_tools", "resource_id", "tool_id"
    end
    
    STDERR.puts "\ndone."
  end
end
