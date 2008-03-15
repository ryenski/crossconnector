class FixInvitationsTable < ActiveRecord::Migration
  def self.up
    STDERR.puts "Migrating to version 17..."    
    
    Invitation.find(:all).each { |inv| inv.update_attribute(:invitation_code, inv.email) unless inv.email.nil? }
    remove_column "invitations", "email"
    remove_column "invitations", "code"
    execute "alter table invitations drop CONSTRAINT invitations_email_key;"
    
    STDERR.puts "done."
     
  end

  def self.down
    STDERR.puts "Migrating down from version 17..."    
    
    Invitation.find(:all).each { |inv| inv.update_attribute(:email, inv.invitation_code) }
    
    add_column "invitations", "email", :string
    add_column "invitations", "code", :string
    # execute "ALTER TABLE invitations ADD CONSTRAINT invitations_email_key UNIQUE (email)"
    
    STDERR.puts "done."
  end
end
