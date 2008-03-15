class AddResourceTypeColumn < ActiveRecord::Migration
  def self.up
    STDERR.puts "Migrating to version 12..."    
    
    add_column "resources", "type", :string, :limit => 20
    
    STDERR.puts "done."
  end

  def self.down
    STDERR.puts "Migrating down from version 12..."    
    
    remove_column "resources", "type"
    
    STDERR.puts "done."
  end
end
