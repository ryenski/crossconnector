class AddFirstEventField < ActiveRecord::Migration
  def self.up
    STDERR.puts "Migrating to version 9..."
    
    Project.transaction do
      add_column "projects", "first_event", :datetime
    
      begin
        STDERR.puts "Starting to fix the data..."
        
        Project.find(:all).each{ |obj| obj.update_attribute(:first_event, obj.events.first.start_date) unless obj.events.first.nil? or obj.events.empty? }

      rescue Exception => e
       STDERR.puts "An error occurred fixing the data (#{e})" 
      end
    end
    
    STDERR.puts "done."
  end

  def self.down
    STDERR.print "Migrating down from version 9... "
    
    remove_column "projects", "first_event"
    
    STDERR.print "done."
  end
end


