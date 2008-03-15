class AddInvoicePeriod < ActiveRecord::Migration
  def self.up
    
    add_column :invoices, :period_start, :datetime
    add_column :invoices, :period_end, :datetime
    add_column :invoices, :payment_method, :string
    rename_column :invoices, :billing_last_four, :payment_last_four
    
  end

  def self.down

    remove_column :invoices, :period_start
    remove_column :invoices, :period_end
    remove_column :invoices, :payment_method, :string
    rename_column :invoices, :payment_last_four, :billing_last_four
  end
end
