class RemoveSimpleReadCounters < ActiveRecord::Migration
  def self.up
    
    STDERR.puts "Migrating to version 7..."
    STDERR.puts "Removing simple read counters... "
    
    remove_column "projects", "read_counter"
    remove_column "tools", "read_counter"
    remove_column "messages", "read_counter"
    
    STDERR.puts "done."
    
  end

  def self.down
    
    STDERR.print "Migrating down from version 7... "
    add_column "projects", "read_counter", :integer, :default => 0
    add_column "tools", "read_counter", :integer, :default => 0
    add_column "messages", "read_counter", :integer, :default => 0
    
    Project.update_all("read_counter = 0")
    Tool.update_all("read_counter = 0")
    Message.update_all("read_counter = 0")
    
    STDERR.print "done."
    
  end
end
