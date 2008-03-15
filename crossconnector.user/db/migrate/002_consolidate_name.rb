class TempUser < ActiveRecord::Base
  set_table_name 'users'
end


class ConsolidateName < ActiveRecord::Migration
  def self.up
    STDERR.print "Migrating up to version 2... "
    
    TempUser.transaction do
      STDERR.print "fixing names... "
      add_column :users, :name, :string, :limit => 500
    
      TempUser.find(:all).each do |user| 
        user.name = "#{user.first_name} #{user.last_name}"
        user.save
      end
      STDERR.print "removing columns from users table... "
      remove_column :users, :first_name
      remove_column :users, :last_name
    end
    STDERR.puts "Done."
  end

  def self.down
    
    TempUser.transaction do
      STDERR.print "Adding back first_name and last_name... "
      add_column :users, :first_name, :string, :limit => 255
      add_column :users, :last_name, :string, :limit => 255
    
      STDERR.print "Splitting names... "
      
      TempUser.find(:all).each do |user| 
        unless user.name.nil?
          user.first_name = user.name.split.first
          user.last_name = user.name.split.last
          user.save
        end
      end
      STDERR.print "Removing the name column... "
      remove_column :users, :name
      
    end
    STDERR.puts "Done"
  end
  
end
