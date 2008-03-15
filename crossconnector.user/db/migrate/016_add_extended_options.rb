class AddExtendedOptions < ActiveRecord::Migration
  def self.up
    STDERR.puts "Migrating to version 16..."    
    
    add_column "messages", "extended", :text
    add_column "messages", "extended_html", :text
    
    STDERR.puts "done."
  end

  def self.down
    STDERR.puts "Migrating down from version 16..."    
    
    Message.find(:all).each { |msg| msg.update_attributes(:body => msg.body + msg.extended, :body_html => msg.body_html + msg.extended_html) }
    
    remove_column "messages", "extended"
    remove_column "messages", "extended_html"
    
    STDERR.puts "done."
  end
end
