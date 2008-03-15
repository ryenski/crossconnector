class AddReadCounters < ActiveRecord::Migration
  def self.up
    # Messages table already has read_counter
    
    STDERR.puts "Migrating to version 5..."
    add_column "projects", "read_counter", :integer, :default => 0
    add_column "tools", "read_counter", :integer, :default => 0
    
    Project.update_all("read_counter = 0")
    Tool.update_all("read_counter = 0")
    
    STDERR.puts "done."
  end

  def self.down
    STDERR.print "Migrating down from version 5... "
    remove_column "projects", "read_counter"
    remove_column "tools", "read_counter"
    STDERR.print "done."
  end
end
