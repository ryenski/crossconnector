# Schema as of Fri Oct 06 12:31:46 CDT 2006 (schema version 37)
#
#  id                  :integer       not null
#  title               :string(255)   
#  permalink           :string(255)   
#  author              :string(255)   
#  body                :text          
#  body_html           :text          
#  excerpt             :text          
#  keywords            :string(255)   
#  draft               :integer       default(0)
#  created_at          :datetime      
#  updated_at          :datetime      
#  deleted             :integer       
#  deleted_at          :datetime      
#

class Page < ActiveRecord::Base
  before_save :transform_body
  
  def transform_body
    self.body_html = RedCloth.new(self.body, [ :hard_breaks ]).to_html(:textile) unless self.body.empty?    
  end
end
