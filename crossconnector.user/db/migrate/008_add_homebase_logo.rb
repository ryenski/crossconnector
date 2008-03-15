class AddHomebaseLogo < ActiveRecord::Migration
  def self.up
    STDERR.puts "Migrating to version 8..."
    
    add_column "homebases", "logo", :string
    
    STDERR.puts "done."
  end

  def self.down
    STDERR.print "Migrating down from version 8... "
    
    remove_column "homebases", "logo"
    
    STDERR.print "done."
  end
end
