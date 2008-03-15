# Schema as of Fri Oct 06 12:31:46 CDT 2006 (schema version 37)
#
#  id                  :integer       not null
#  first_name          :string(255)   
#  last_name           :string(255)   
#  invitation_code     :string(255)   
#  created_at          :datetime      
#  used_at             :datetime      
#  use_counter         :integer       default(0)
#

require 'digest/sha1'

class Invitation < ActiveRecord::Base
    
  def generate_invitation_code
    return self.new_invitation_code
  end

  protected
  
  @@security_code = "6rl56iuxledr"
  
  def self.hashed(str)
    Digest::SHA1.hexdigest("#{@@security_code}--#{str}--")
  end
  
  # If no code was given, generate a random hashed code. 
  # Otherwise, just return the code. 
  def new_invitation_code
    if self.invitation_code.nil?
      write_attribute(:invitation_code, self.class.name.hashed(Time.now.to_i.to_s + rand.to_s))
      update_without_callbacks
    end
    return self.invitation_code
  end
  
  validates_presence_of :invitation_code
  validates_uniqueness_of :invitation_code
  
end
