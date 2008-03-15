require 'permalink'

class AddPermalinks < ActiveRecord::Migration
  def self.up
    STDERR.puts "Migrating to version 19... "
    
    add_column :messages, :permalink, :string rescue nil
    add_index :messages, :permalink rescue nil
    messages = Message.find(:all)
    STDERR.puts "Processing #{messages.length} messages."
    messages.each { |m| m.update_attribute("permalink", m.generate_permalink) }
    
    
    add_column :projects, :permalink, :string rescue nil
    add_index :projects, :permalink rescue nil
    projects = Project.find(:all)
    STDERR.puts "\nProcessing #{projects.length} projects."
    projects.each { |p| p.update_attribute("permalink", p.generate_permalink) }
    
    
    add_column :resources, :permalink, :string rescue nil
    add_index :resources, :permalink rescue nil
    resources = Resource.find(:all)
    STDERR.puts "\nProcessing #{messages.length} resources."
    resources.each { |r| r.update_attribute("name", r[:name]) if r.name.blank? }
    resources.each { |r| r.update_attribute("permalink", r.generate_permalink) }
    
    STDERR.puts "\nDone."
  end

  def self.down
    STDERR.puts "Migrating down from version 19..."    
    
    remove_index :messages, :permalink
    remove_column :messages, :permalink
    
    remove_index :projects, :permalink
    remove_column :projects, :permalink
    
    remove_index :resources, :permalink
    remove_column :resources, :permalink
      
    STDERR.puts "done."
  end
end
