class CreateEmails < ActiveRecord::Migration
  def self.up
    say("Adding Emails table. ")
    create_table :emails do |t|
      t.column :from, :string
      t.column :to, :string
      t.column :cc, :string
      t.column :bcc, :string
      t.column :charset, :string
      #t.column :headers, :string
      t.column :subject, :string
      t.column :body, :string
      t.column :raw, :string
    end
    
    say("Adding email_id to Invoices")
    add_column "invoices", "email_id", :integer
    
    announce("Success.")
  end

  def self.down
    drop_table :emails
    remove_column "invoices", "email_id"

    # We don't ever want to delete this table.
    # raise IrreversibleMigration
  end
end

