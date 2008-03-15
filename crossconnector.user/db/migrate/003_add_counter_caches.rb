class TempHomebase < ActiveRecord::Base
  set_table_name 'homebases'
end

class AddCounterCaches < ActiveRecord::Migration
  def self.up
    
    TempHomebase.transaction do
      STDERR.puts "Migrating to version 3..."
      begin
        STDERR.puts "Updating schemas..."
        
        add_column "homebases", "messages_count", :integer, :default => 0
        TempHomebase.update_all("messages_count = 0")
        
        add_column "homebases", "projects_count", :integer, :default => 0
        TempHomebase.update_all("projects_count = 0")
        
        add_column "homebases", "tools_count", :integer, :default => 0
        TempHomebase.update_all("tools_count = 0")
        
        add_column "homebases", "addresses_count", :integer, :default => 0
        TempHomebase.update_all("addresses_count = 0")
        
        add_column "homebases", "groups_count", :integer, :default => 0
        TempHomebase.update_all("groups_count = 0")
        
        add_column "messages", "comments_count", :integer, :default => 0
        Message.update_all("comments_count = 0")
        
        add_column "projects", "messages_count", :integer, :default => 0
        Project.update_all("messages_count = 0")
        
        add_column "projects", "events_count", :integer, :default => 0 
        Project.update_all("events_count = 0")
        
        STDERR.puts "Finished updating schemas..."
      rescue Exception => e
        STDERR.puts "An error occurred when updating the schemas. (#{e})"    
      end
    
      begin
        STDERR.puts "Starting to fix the data..."
        TempHomebase.find(:all).each{ |obj| obj.update_attribute(:messages_count, TempHomebase.find_by_sql(["select count(id) from messages where homebase_id = ?", obj.id])[0].count.to_i) }
        TempHomebase.find(:all).each{ |obj| obj.update_attribute(:projects_count, TempHomebase.find_by_sql(["select count(id) from projects where homebase_id = ?", obj.id])[0].count.to_i) }
        TempHomebase.find(:all).each{ |obj| obj.update_attribute(:tools_count, TempHomebase.find_by_sql(["select count(id) from tools where homebase_id = ?", obj.id])[0].count.to_i) }
        TempHomebase.find(:all).each{ |obj| obj.update_attribute(:addresses_count, TempHomebase.find_by_sql(["select count(id) from addresses where homebase_id = ?", obj.id])[0].count.to_i) }
        TempHomebase.find(:all).each{ |obj| obj.update_attribute(:groups_count, TempHomebase.find_by_sql(["select count(id) from groups where homebase_id = ?", obj.id])[0].count.to_i) }

        Message.find(:all).each{ |obj| obj.update_attribute(:comments_count, Message.find_by_sql(["select count(id) from comments where message_id = ?", obj.id])[0].count.to_i) }
        Project.find(:all).each{ |obj| obj.update_attribute(:messages_count, Project.find_by_sql(["select count(id) from messages where project_id = ?", obj.id])[0].count.to_i) }
        Project.find(:all).each{ |obj| obj.update_attribute(:events_count, Project.find_by_sql(["select count(id) from events where project_id = ?", obj.id])[0].count.to_i) }
      rescue Exception => e
       STDERR.puts "An error occurred fixing the data (#{e})" 
      end

      STDERR.puts "Finished migrating to version 3..."
    end
  end

  def self.down    
    begin
      STDERR.puts "Migrating down from version 3..."
      
      TempHomebase.transaction do
        remove_column "homebases", "messages_count"
        remove_column "homebases", "projects_count"
        remove_column "homebases", "tools_count"
        remove_column "homebases", "addresses_count"
        remove_column "homebases", "groups_count"
        remove_column "messages", "comments_count"
        remove_column "projects", "messages_count"
        remove_column "projects", "events_count"
        STDERR.puts "Successfully migrated down from version 3..."
      end

    rescue Exception => e
      STDERR.puts "An error occurred during the migration (#{e})"    
    end

  end
end
