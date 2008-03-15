class AddInvitationCode < ActiveRecord::Migration
  def self.up
    STDERR.puts "Migrating to version 14..."    
    
    add_column "invitations", "code", :string
    execute "ALTER TABLE invitations ALTER COLUMN email DROP NOT NULL;"
    
    Invitation.find(:all).each { |inv| inv.update_attribute(:code, inv.email) }
    
    STDERR.puts "done."
  end

  def self.down
    STDERR.puts "Migrating down from version 14..."    
    
    remove_column "invitations", "code"
    execute "ALTER TABLE invitations ALTER COLUMN email SET NOT NULL;"
    
    STDERR.puts "done."
  end
end
