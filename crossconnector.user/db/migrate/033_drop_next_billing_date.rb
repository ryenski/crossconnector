class DropNextBillingDate < ActiveRecord::Migration
  def self.up
    remove_column "subscriptions", "next_billing_date"
    remove_column "subscriptions", "status"
    add_column "subscriptions", "old_identifiers", :text
  end

  def self.down
    add_column "subscriptions", "next_billing_date", :datetime
    add_column "subscriptions", "status", :string
    remove_column "subscriptions", "old_identifiers"
  end
end
