# Schema as of Fri Oct 06 12:31:46 CDT 2006 (schema version 37)
#
#  id                  :integer       not null
#  title               :string(255)   
#  description         :text          
#  description_html    :text          
#  created_at          :datetime      
#  expires_at          :datetime      
#

class Alert < ActiveRecord::Base
  before_save :transform_description
  
  def transform_description
    self.description_html = RedCloth.new(self.description).to_html(:textile) unless self.description.nil?
  end
  
  def self.find_current_alert
    self.find(:first, :conditions => ["expires_at > ?", Time.now])
  end
  
  def expire
    self.update_attribute(:expires_at, Time.now)
  end
  
end
