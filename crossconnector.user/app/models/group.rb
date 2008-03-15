# Schema as of Fri Oct 06 12:31:46 CDT 2006 (schema version 37)
#
#  id                  :integer       not null
#  homebase_id         :integer       not null
#  created_by          :integer       
#  name                :string(255)   not null
#  position            :integer       
#

class Group < ActiveRecord::Base
  
  belongs_to :homebase, :counter_cache => true
  belongs_to :user
  has_and_belongs_to_many :addresses
  has_and_belongs_to_many :messages
  has_and_belongs_to_many :projects
  has_and_belongs_to_many :files, :class_name => "Resource"
  
  
  
  validates_length_of       :name, :within => 1..255
end
