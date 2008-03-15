# Schema as of Fri Oct 06 12:31:46 CDT 2006 (schema version 37)
#
#  id                  :integer       not null
#  homebase_id         :integer       not null
#  created_by          :integer       
#  email               :string(255)   not null
#  name                :string(255)   
#  organization        :string(255)   
#  address1            :string(255)   
#  address2            :string(255)   
#  city                :string(255)   
#  state               :string(50)    
#  postal              :string(20)    
#  country             :string(255)   
#  time_zone           :string(255)   
#  phone               :string(20)    
#  website             :string(255)   
#  created_at          :datetime      
#  updated_at          :datetime      
#  updated_by          :integer       
#  position            :integer       
#

class Address < ActiveRecord::Base
  
  belongs_to              :homebase, :counter_cache => true
  belongs_to              :user, :foreign_key => "created_by"
  has_and_belongs_to_many :groups
  has_and_belongs_to_many :messages
  has_and_belongs_to_many :projects
  has_and_belongs_to_many :files, :class_name => "Resource"




  def self.toggle_address_in_group(address_id,group_id,toggle)
    begin
      address = Address.find(address_id)
      group = Group.find(group_id)
      case toggle
      when :add
        group.addresses.push_with_attributes(address)
      when :delete
        group.addresses.delete(address)
      end
    rescue Exception => e
      raise ActiveRecord::RecordNotFound
    end    
  end
  
  
  # These are depreciated - use toggle_address_in_group instead
  def self.add_address_to_group(address_id,group_id)
    address = Address.find(address_id)
    group = Group.find(group_id)
    group.addresses.push_with_attributes(address)
  end  
  
  def self.remove_address_from_group(address_id,group_id)
    address = Address.find(address_id)
    group = Group.find(group_id)
    group.addresses.delete(address)
  end
  

  validates_format_of       :email, :on => :save, :with => /^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/
  validates_length_of       :email, :maximum => 255, :on => :save
  validates_length_of       :email, :minimum => 1, :on => :save
  
end
