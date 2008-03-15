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

class User < ActiveRecord::Base
  
  attr_accessor :card_expiration_date
  attr_accessor :card_number
  attr_accessor :payment_method
  #attr_accessor :homebase_subdomain
  #attr_accessor :homebase_name
  attr_accessor :subscription_plan_id
  attr_accessor :password, :password_confirmation
  attr_accessor :terms
  attr_accessor :account_address, :account_name
  
  cattr_accessor :current_user
  
  
  has_many    :messages,   :foreign_key => "created_by" #, :conditions => "draft != 1"
  has_many    :draft_messages, :foreign_key => "created_by", :class_name => "Message", :conditions => "draft = 1"
  
  has_many    :addresses,  :foreign_key => "created_by"
  has_many    :groups,     :foreign_key => "created_by", :order => "position ASC"
  has_many    :files,      :foreign_key => "created_by", :class_name => "Resource"
  has_many    :projects,   :foreign_key => "created_by"
  has_one     :homebase,   :foreign_key => "created_by", :dependent => true
  belongs_to  :homebase
  
  before_save :fix_url
  after_create :create_with_security_token
  
  
  def self.authenticate(username,pass,homebase_id=Homebase.current_homebase.id)
    return nil if username.blank? or pass.blank?
    conditions = /\w+[@][\w.]+/.match(username) ? "email" : "username"
    
    u = find(:first, :conditions => ["LOWER(#{conditions}) = ? AND homebase_id = ?", username.downcase, homebase_id])
    return nil if u.nil?
    
    u = find(:first, :conditions => ["LOWER(#{conditions}) = ? AND salted_password = ? AND homebase_id = ?", username.downcase, ActiveRecord::PasswordSystem.encrypt(pass,u.salt), homebase_id])
    return nil if u.nil?
    
    u.update_login_counter
    return u
  end
  
  def self.authenticate?(email,password)
    user = self.authenticate(email,password)
    return false if user.nil?
    return true if user.email == email
    false
  end
  
  # Setting clear_token=true will delete the token immediately. 
  # Setting it to false will leave it. 
  # Set it to true for initial login, when it is only supposed to be used once. 
  # Set it to false for subscription requests, since the person may need to use it more than once.
  def self.authenticate_with_token(token, homebase_id=Homebase.current_homebase.id, clear_token=true)
    user = find(:first, :conditions => ["security_token = ? AND homebase_id = ?", token, homebase_id])
    return nil if user.nil? or user.token_expired?
    return nil if user.homebase.created_by != user
    user.clear_security_token if clear_token == true
    user.update_login_counter
    return user
  end
  
  def update_login_counter
    self.update_attributes(:logged_in_at => Time.now, :login_counter => (self.login_counter + 1))
  end
  
  def clear_security_token
    self.update_attributes(:security_token => nil, :token_expiry => nil)
  end
  
  def token_expired?
    self.security_token and self.token_expiry and (Time.now > self.token_expiry)
  end
    
  def create_with_security_token
    self.generate_security_token(1)
  end
  
  def generate_security_token(hours = nil)
    if not hours.nil? or self.security_token.nil? or self.token_expiry.nil? or 
        (time.now.to_i + token_lifetime / 2) >= self.token_expiry.to_i
      return new_security_token(hours)
    else
      return self.security_token
    end
  end
  
  def fix_url
    if !self.website.nil?
      self.url = "http://#{self.website}" if !self.website.include?("http://")
    end
  end

  
  
  def can_edit_projects?
    self.can_edit_projects == 1 or self.class == User
  end
  
  def can_edit_messages?
    self.can_edit_messages == 1 or self.class == User
  end
  
  def can_edit_files?
    self.can_edit_files == 1 or self.class == User
  end
  
  def can_edit_addresses?
    self.can_edit_addresses == 1 or self.class == User
  end 
  
  def can_edit_leaders?
    self.can_edit_leaders == 1 or self.class == User
  end
  
  def decrypted_password
    ActiveRecord::PasswordSystem.decrypt(self.salted_password, self.salt)
  end
  
  protected
  
  def new_security_token(hours = nil)
    write_attribute('security_token', ActiveRecord::PasswordSystem.hashed(Time.now.to_i.to_s + rand.to_s))
    write_attribute('token_expiry', Time.at(Time.now.to_i + token_lifetime(hours)))
    update_without_callbacks
    return self.security_token
  end
  
  def token_lifetime(hours = nil)
    if hours.nil?
      App::CONFIG[:security_token_life_hours] * 60 * 60
    else
      hours * 60 * 60
    end
  end
  
  def fix_case
    self.email = self.email.downcase if self.email
  end
  
  before_validation :fix_case
  
  validates_presence_of     :name, :on => :create

  validates_presence_of     :email, :on => :save, :if => Proc.new { |u| !u.deleted? }
  validates_format_of       :email, :on => :save, :with => /^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/, :if => Proc.new { |u| !u.deleted? }
  validates_length_of       :email, :on => :save, :within => 1..255, :if => Proc.new { |u| !u.deleted? }
  validates_uniqueness_of   :email, :on => :save, 
                            :scope => "homebase_id", 
                            :message => "address is already being used by someone in this homebase.", 
                            :allow_nil => false, 
                            :if => Proc.new { |u| !u.homebase_id.nil? && !u.deleted? }

  validates_uniqueness_of   :username, :on => :save, 
                            :scope => "homebase_id", 
                            :message => "is already being used by someone in this homebase.", 
                            :if=> Proc.new { |u| !u.username.blank? }

  validates_presence_of     :password, :on => :create

  validates_confirmation_of :password, :on => :save, :if=> Proc.new { |u| !u.password.blank? }
  validates_length_of       :password, :on => :save, :within => 4..255, :if=> Proc.new { |u| !u.password.blank? }

  validates_acceptance_of   :terms, :on => :create, :message => "must be accepted. Please remember to check the box next to the Terms of Service if you agree to the terms"
  

end
