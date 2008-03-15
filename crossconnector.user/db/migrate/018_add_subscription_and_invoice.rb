class AddSubscriptionAndInvoice < ActiveRecord::Migration
  def self.up
    STDERR.puts "Migrating to version 18... "
    # Drop the original invoices table
    drop_table "invoices"
    
    STDERR.print "Creating Subscriptions table. "
    create_table "subscriptions", :force => true do |t|
      t.column "homebase_id", :integer
      t.column "created_at", :datetime
      t.column "updated_at", :datetime
      t.column "amount", :integer, :default => 0, :null => false
      t.column "last_action", :string
      t.column "installments", :integer
      t.column "start_date", :datetime
      t.column "periodicity", :string
      t.column "comments", :text
    end
    
    STDERR.print "Creating Invoices table. "
    create_table "invoices", :force => true do |t|
      t.column "subscription_id", :integer
      t.column "total", :integer, :default => 0, :null => false
      t.column "created_at", :datetime
      t.column "comment", :text
      t.column "billing_name", :string
      t.column "billing_address", :string
      t.column "billing_city", :string
      t.column "billing_state", :string
      t.column "billing_zip", :string
      t.column "billing_country", :string
      t.column "billing_last_four", :string
      t.column "snapshot", :text
    end

    STDERR.print "Creating InvoiceItems table. "
    create_table "invoice_items", :force => true do |t|
      t.column "invoice_id", :integer
      t.column "price", :integer, :default => 0, :null => false
      t.column "period", :string
      t.column "quantity", :integer
      t.column "comment", :text
      t.column "name", :string
      t.column "description", :text
    end

    STDERR.puts "Done."
  end

  def self.down
    STDERR.puts "Migrating down from version 18... "
    
    drop_table "invoice_items"
    drop_table "invoices"
    drop_table "subscriptions"
    
    # Add back the original invoices table
    create_table "invoices", :force => true do |t|
      t.column "homebase_id", :integer
      t.column "amount", :integer, :default => 0, :null => false
      t.column "created_at", :datetime
      t.column "updated_at", :datetime
    end
    STDERR.puts "done. "
  end
end
