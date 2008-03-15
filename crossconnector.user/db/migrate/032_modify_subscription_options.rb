class ModifySubscriptionOptions < ActiveRecord::Migration
  def self.up
    
    announce "Modifying Subscription Options."
    Subscription.transaction do
      say "adding billing_date fields. "
      add_column "subscriptions", "next_billing_date", :datetime
      add_column "subscriptions", "last_billing_date", :datetime
      
    end
    
  end

  def self.down
    Subscription.transaction do
      remove_column "subscriptions", "next_billing_date"
      remove_column "subscriptions", "last_billing_date"
    end
  end
end
