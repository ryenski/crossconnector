class AddExtendedAboutUs < ActiveRecord::Migration
  def self.up
    STDERR.puts "Migrating to version 13..."    
    
    add_column "homebases", "profile_extended", :text
    
    STDERR.puts "done."
  end

  def self.down
    STDERR.puts "Migrating down from version 13..."    
    
    remove_column "homebases", "profile_extended"
    
    STDERR.puts "done."
  end
end
