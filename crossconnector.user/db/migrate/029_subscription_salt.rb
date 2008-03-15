class SubscriptionSalt < ActiveRecord::Migration
  def self.up
    add_column "subscriptions", "salt", :string
  end

  def self.down
    remove_column "subscriptions", "salt"
  end
end
