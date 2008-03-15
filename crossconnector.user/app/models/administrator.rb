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

class Administrator < User
  
  
  def self.authenticate(username,pass,security_code)
    return false unless check_security_code(security_code)
    u = find(:first, :conditions => ["username = ? AND type = ?", username, "Administrator"])
    find(:first, :conditions => ["username = ? AND salted_password = ? AND type = ?", username, ActiveRecord::PasswordSystem.encrypt(pass, u.salt), "Administrator"]) 
  end
  
  
  protected
  
  @@security_code = "1d97d3f9958a36e80e56e6daeaeec738c791cbf1"
  
  def self.check_security_code(code)
    return true if ActiveRecord::PasswordSystem.hashed(code) == @@security_code
    return false
  end
  
  
  
end
