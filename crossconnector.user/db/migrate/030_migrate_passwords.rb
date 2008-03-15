#require 'password_system'
#ActiveRecord::Base.class_eval do
#  include ActiveRecord::PasswordSystem
#end


class MigratePasswords < ActiveRecord::Migration
  def self.up
    STDERR.puts "Migrating old passwords... "
    
    User.transaction do
      STDERR.print "starting. \n"
      users = User.find(:all)
      
      for user in users
        unless user.salted_password.nil? or user.salt.nil?
          #user.password = user.decrypted_password
          STDERR.print "#{user.id}"
          user.update_attribute(:salted_password, ActiveRecord::PasswordSystem.encrypt(user.decrypted_password, user.salt)) rescue " good "
          STDERR.print "."
        end
      end
      
      STDERR.puts "done. Success! \n"
    end
  end

  def self.down
    STDERR.puts "There is no downgrade from version 30... moving on."
  end
end


# ActiveRecord::PasswordSystem.encrypt(user.decrypted_password, user.salt)