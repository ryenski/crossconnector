# Schema as of Fri Oct 06 12:31:46 CDT 2006 (schema version 37)
#
#  id                  :integer       not null
#  message_id          :integer       
#  name                :string(255)   
#  email               :string(255)   
#  url                 :string(255)   
#  ip                  :string(15)    
#  body                :text          
#  body_html           :text          
#  created_at          :datetime      
#  updated_at          :datetime      
#  updated_by          :integer       
#

class Comment < ActiveRecord::Base
  
  belongs_to :message, :counter_cache => true
  
  validates_presence_of :body
  validates_presence_of :name

  before_save :transform_body
  before_save :fix_url
  
  # Used for tricking spam bots
  attr_accessor :phone
  
  def transform_body
    self.body_html = RedCloth.new(self.body, [:hard_breaks] ).to_html unless self.body.nil?
  end
  
  def fix_url
    unless self.url.blank?
      self.url = "http://#{self.url}" unless self.url.include?("http://")
    end
  end
  
  def message_permalink
    "http://#{Homebase.current_homebase.subdomain}.#{App::CONFIG[:app_domain]}/message/#{self.message.permalink}"
  end
  
end
