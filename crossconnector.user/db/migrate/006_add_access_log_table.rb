class AddAccessLogTable < ActiveRecord::Migration
  def self.up
    STDERR.puts "Migrating to version 6... "
    
    create_table "access_logs", :force => true do |t|
      t.column "homebase_id", :integer
      t.column "ip", :string
      t.column "request", :text
      t.column "referrer", :text
      t.column "user_agent", :string
      t.column "language", :string
      t.column "host", :string
      t.column "created_at", :datetime
      t.column "public_homebase_id", :integer
      t.column "message_id", :integer
      t.column "project_id", :integer
      t.column "tool_id", :integer
    end
    
    add_column "homebases", "access_logs_count", :integer, :default => 0
    Homebase.update_all("access_logs_count = 0")
    
    add_column "messages", "access_logs_count", :integer, :default => 0
    Message.update_all("access_logs_count = 0")
    
    add_column "projects", "access_logs_count", :integer, :default => 0
    Project.update_all("access_logs_count = 0")
    
    add_column "tools", "access_logs_count", :integer, :default => 0
    Tool.update_all("access_logs_count = 0")
    
    STDERR.puts "done."
  end

  def self.down
    STDERR.print "Migrating down from version 6... "
    
    drop_table "access_logs"
    remove_column("homebases", "access_logs_count")
    remove_column("messages", "access_logs_count")
    remove_column("projects", "access_logs_count")
    remove_column("tools", "access_logs_count")
    
    STDERR.print "done."
  end
end
