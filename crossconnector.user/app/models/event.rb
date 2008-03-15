# Schema as of Fri Oct 06 12:31:46 CDT 2006 (schema version 37)
#
#  id                  :integer       not null
#  project_id          :integer       not null
#  name                :string(255)   
#  start_date          :datetime      
#  end_date            :datetime      
#  body                :text          
#  body_html           :text          
#  created_at          :datetime      
#  updated_at          :datetime      
#  updated_by          :integer       
#  duration_unit       :string(25)    
#  duration_n          :integer       
#

class Event < ActiveRecord::Base
  
  belongs_to :project, :counter_cache => true
  
  before_save :transform_body 
  before_save :fix_name
  
  after_save :set_first_event_for_project
  before_destroy :set_first_event_for_project_before_destroy
  
  
  protected
  
  def set_first_event_for_project
    self.project.update_attribute(:first_event, self.project.events.first.start_date) rescue nil
  end
  
  def set_first_event_for_project_before_destroy
    self.project.update_attribute(:first_event, self.project.events[1].start_date) unless self.project.events[1].nil?
  end
  
  def transform_body
    self.body_html = RedCloth.new(self.body, [ :hard_breaks ]).to_html(:textile) unless self.body.nil?
  end
  
  def fix_name
    self.name = "Unnamed event" if self.name.blank?
  end
  
  
  #validates_presence_of :name
  #validates_presence_of :start_date
end
