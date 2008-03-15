class AddInvoiceOptions < ActiveRecord::Migration
  def self.up

    # Associate invoices with homebases, rather than users
    rename_column :invoices, :user_id, :homebase_id rescue nil
    
    # Date trial period ends
    add_column :homebases, :trial_period_ends_at, :datetime, :default => nil
    
  end
  
  def self.down
    rename_column :invoices, :homebase_id, :user_id rescue nil
    remove_column :homebases, :trial_period_ends_at
  end
end
