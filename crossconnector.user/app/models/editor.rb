# Schema as of Fri Oct 06 12:31:46 CDT 2006 (schema version 37)
#
#  id                  :integer       not null
#  homebase_id         :integer       
#  type                :string(20)    
#  created_by          :integer       
#  username            :string(255)   
#  email               :string(255)   
#  salt                :string(40)    
#  salted_password     :string(255)   
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
#  logged_in_at        :datetime      
#  login_counter       :integer       default(0)
#  verified            :integer       default(0)
#  security_token      :string(40)    
#  token_expiry        :datetime      
#  deleted             :integer       default(0)
#  deleted_at          :datetime      
#  can_edit_messages   :integer       default(1)
#  can_edit_projects   :integer       default(1)
#  can_edit_addresses  :integer       default(1)
#  can_edit_files      :integer       default(1)
#  name                :string(500)   
#  can_edit_leaders    :integer       default(1)
#

require 'digest/sha1'
require 'openssl'

class Editor < User
  # An editor is a kind of user. 
  # belongs_to :user
  belongs_to :homebase  
  
  protected
  #before_save :crypt_password
  


end
