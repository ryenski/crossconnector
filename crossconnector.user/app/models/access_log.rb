# Schema as of Fri Oct 06 12:31:46 CDT 2006 (schema version 37)
#
#  id                  :integer       not null
#  ip                  :string(255)   
#  request             :text          
#  referrer            :text          
#  user_agent          :string(255)   
#  language            :string(255)   
#  host                :string(255)   
#  created_at          :datetime      
#  public_homebase_id  :integer       
#  message_id          :integer       
#  project_id          :integer       
#  resource_id         :integer       
#  homebase_id         :integer       
#

class AccessLog < ActiveRecord::Base
  # PublicHomebaseId is named this way to prevent UserMonitor from automatically populating the homebase_id
  belongs_to :homebase, :counter_cache => true, :foreign_key => "public_homebase_id"
  belongs_to :message, :counter_cache => true
  belongs_to :project, :counter_cache => true
  belongs_to :resource, :counter_cache => true
  
end
