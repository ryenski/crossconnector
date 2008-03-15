class RenameFilenameField < ActiveRecord::Migration
  def self.up
    STDERR.puts "Migrating to version 15..."    
    
    rename_column "resources", "filename", "file"
    
    STDERR.puts "done."
  end

  def self.down
    STDERR.puts "Migrating down from version 15..."    
    
    rename_column "resources", "file", "filename"
    
    STDERR.puts "done."
  end
end
