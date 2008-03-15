class ChangePlans < ActiveRecord::Migration
  def self.up
    
    # Create new subscription plan
    # Select all Homebases
    # For each, validate subscription
    # Set Subscription.plan to new plan
    
    
    SubscriptionPlan.transaction do
      
      SubscriptionPlan.update_all("visible = 0")
      
      free = SubscriptionPlan.find_by_name "Free"
      free.update_attributes(:name => "Free-Limited")
      
      # For some reason the index is messed up. Execute by SQL
      execute(%Q{INSERT INTO subscription_plans ("name", "visible", "price", "description", "id") VALUES('Free', 1, 0, 'Donation supported.', 9);})
      plan = SubscriptionPlan.find(9)
      
      # Projects
      execute(%Q{INSERT INTO subscription_plan_items (subscription_plan_id, subscription_plan_privelege_id, plan_limit) VALUES (9, 1, 0);})
      # Storage
      execute(%Q{INSERT INTO subscription_plan_items (subscription_plan_id, subscription_plan_privelege_id, plan_limit) VALUES (9, 2, 10);})
      # Messages
      execute(%Q{INSERT INTO subscription_plan_items (subscription_plan_id, subscription_plan_privelege_id, plan_limit) VALUES (9, 3, 0);})
      
      Subscription.update_all("subscription_plan_id = 9")
      
    end
  end

  def self.down
    # raise IrreversableMigration
    transaction do
      SubscriptionPlan.find(9).destroy
      
      free = SubscriptionPlan.find_by_name "Free-Limited"
      free.update_attributes(:name => "Free")
    end
  end
end
