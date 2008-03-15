# Schema as of Fri Oct 06 12:31:46 CDT 2006 (schema version 37)
#
#  id                  :integer       not null
#  name                :string(255)   
#  price               :integer       default(0), not null
#  description         :text          
#  visible             :integer       default(1), not null
#

class SubscriptionPlan < ActiveRecord::Base
  
  #has_many :homebases
  has_and_belongs_to_many :priveleges, :class_name => "SubscriptionPlanPrivelege", :join_table => "subscription_plan_items"
  has_many :subscriptions
  
  
  def self.find_visible
    self.find(:all, :order => "price DESC", :conditions => "visible = '1'")
  end
  
  def money
    Money.new(self.price)
  end
  
end
