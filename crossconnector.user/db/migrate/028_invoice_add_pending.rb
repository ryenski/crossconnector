class InvoiceAddPending < ActiveRecord::Migration
  def self.up
    add_column "invoices", "pending", :integer
    add_column "subscriptions", "pending", :integer
  end

  def self.down
    remove_column "invoices", "pending"
    remove_column "subscriptions", "pending"
  end
end
