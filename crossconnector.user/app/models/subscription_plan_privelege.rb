# Schema as of Fri Oct 06 12:31:46 CDT 2006 (schema version 37)
#
#  id                  :integer       not null
#  name                :string(255)   
#

class SubscriptionPlanPrivelege < ActiveRecord::Base
  
  has_and_belongs_to_many :plans,
                          :class_name => "SubscriptionPlan",
                          :join_table           => "subscription_plan_items", 
                          :order                => "price DESC", 
                          :conditions           => "visible = '1'"
  
end
