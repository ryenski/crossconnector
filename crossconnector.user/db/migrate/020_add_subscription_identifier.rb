class AddSubscriptionIdentifier < ActiveRecord::Migration

  
  def self.up
    STDERR.puts "Migrating to version 20..."    
    
    remove_column "subscriptions", "amount" rescue STDERR.puts "\namount column not found. continuing...\n"
    remove_column "homebases", "trial_period_ends_at" rescue STDERR.puts "\n trial_period column not found. continuing...\n"
    
    add_column "subscriptions", "identifier", :string
    add_column "subscriptions", "name", :string
    add_column "subscriptions", "email", :string
    add_column "subscriptions", "address", :string
    add_column "subscriptions", "address2", :string
    add_column "subscriptions", "city", :string
    add_column "subscriptions", "state", :string
    add_column "subscriptions", "zip", :string
    add_column "subscriptions", "country", :string
    add_column "subscriptions", "subscription_plan_id", :integer
    add_column "subscriptions", "last_four", :string
    add_column "subscriptions", "card_type", :string
    add_column "subscriptions", "price", :integer
    add_column "subscriptions", "trial_ends_at", :datetime
    add_column "subscriptions", "status", :string
    add_column "subscriptions", "coupon_code", :string
    
    
    homebases = Homebase.find(:all)
    STDERR.puts "\nMigrating #{homebases.length} homebases..."
    homebases.each { |h| 
      Subscription.create(:name => h.created_by.name,
                          :email => h.created_by.email,
                          :terms => "1",
                          :price => h.plan.price,
                          :subscription_plan_id => h.plan.id,
                          :homebase_id => h.id,
                          :trial_ends_at => Time.now + 30.days) 
    }
    
    
    STDERR.puts "done."
  end

  def self.down
    
    STDERR.puts "Migrating down from version 20..."    
    
    #add_column "subscriptions", "amount", :integer, :default => 0, :null => false
    add_column "homebases", "trial_period_ends_at", :datetime
    
    remove_column "subscriptions", "identifier"
    remove_column "subscriptions", "name"
    remove_column "subscriptions", "email"
    remove_column "subscriptions", "address"
    remove_column "subscriptions", "address2"
    remove_column "subscriptions", "city"
    remove_column "subscriptions", "state"
    remove_column "subscriptions", "zip"
    remove_column "subscriptions", "country"
    remove_column "subscriptions", "subscription_plan_id"
    remove_column "subscriptions", "last_four"
    remove_column "subscriptions", "card_type"
    remove_column "subscriptions", "price"
    remove_column "subscriptions", "trial_ends_at"
    remove_column "subscriptions", "status"
    remove_column "subscriptions", "coupon_code"
    
    Subscription.destroy_all
    
    STDERR.puts "done."
  end
end
