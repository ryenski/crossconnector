# Schema as of Fri Oct 06 12:31:46 CDT 2006 (schema version 37)
#
#  id                  :integer       not null
#  homebase_id         :integer       not null
#  created_by          :integer       
#  project_id          :integer       
#  subject             :string(255)   
#  body                :text          
#  body_html           :text          
#  keywords            :string(255)   
#  private             :integer       default(0)
#  disable_comments    :integer       default(0)
#  draft               :integer       default(0)
#  created_at          :datetime      
#  updated_at          :datetime      
#  updated_by          :integer       
#  comments_count      :integer       default(0)
#  access_logs_count   :integer       default(0)
#  extended            :text          
#  extended_html       :text          
#  permalink           :string(255)   
#  salted_password     :string(255)   
#  salt                :string(255)   
#

require_dependency "search"

class Message < ActiveRecord::Base

  belongs_to               :homebase, :counter_cache => true
  belongs_to               :user, :foreign_key => "created_by"
  belongs_to               :project, :counter_cache => true
  has_many                 :comments, :order => "created_at ASC"
  has_many                 :files, :class_name => "Resource"
  has_many                 :access_logs
  has_and_belongs_to_many  :addresses
  has_and_belongs_to_many  :groups
  
  acts_as_taggable
  use_permalink :subject  
  searches_on :all
  
  
  before_save :transform_body
  
  attr_accessor :resend_email
  attr_accessor :resend_email_unsent_only
  
  def name
    self.subject rescue nil
  end
  
  def description
    self.body rescue nil
  end
  
  
  
  #
  # Password stuff
  attr_accessor :private_checkbox
  attr_accessor :password
  
  def self.authenticate(permalink, password, homebase_id=Homebase.current_homebase.id)
    return false if password.blank?
    m = find(:first, :conditions => ["permalink = ? and homebase_id = ?", permalink, homebase_id])
    return false if m.nil?
    begin
      m = find(:first, :conditions => ["permalink = ? and salted_password = ?", permalink, ActiveRecord::PasswordSystem.encrypt(password, m.salt)])      
    rescue
      m = Project.find(:first, :conditions => ["permalink = ? and salted_password = ?", m.project.permalink, ActiveRecord::PasswordSystem.encrypt(password, m.salt)])
    end
    
    return false if m.nil?
    return m
  end

  def decrypted_password
    ActiveRecord::PasswordSystem.decrypt(self.salted_password, self.salt)
  end

  #def private
  #  return self.private? ? 1 : 0
  #end
  
  def private?
    return true if self.salted_password
    return true if self.project and self.project.salted_password
    return false
  end
  



  # For some reason the hard_breaks property is not working like it should
  # Hard breaks is broken in RedCloth 3.0.4. Use 3.0.3 instead
  def transform_body
    self.body_html = RedCloth.new(self.body, [ :hard_breaks ]).to_html(:textile) unless self.body.nil?
    self.extended_html = RedCloth.new(self.extended, [ :hard_breaks ]).to_html(:textile) unless self.extended.nil?    
  end
  
  def textilize(text)
  		return '' if text.blank?
  		textilized = RedCloth.new(text, [ :hard_breaks ])
  		textilized.hard_breaks = true if textilized.respond_to?("hard_breaks=")
  		textilized.to_html
  end

  def self.find_received_messages
    # Received messages
    # Sent to the email address of any user in a particular homebase 
    q = ["select * from messages where (id IN (select message_id from groups_messages where group_id IN (select group_id from addresses_groups where address_id IN ( select id from addresses where email IN ( select email from users where homebase_id = ? )))) OR (id IN (select message_id from addresses_messages where address_id IN (select id from addresses where email IN (select email from users where homebase_id = ?))))) AND messages.homebase_id != ? AND messages.draft != 1", Homebase.current_homebase.id, Homebase.current_homebase.id, Homebase.current_homebase.id]
    q[0] << " order by created_at DESC"
    self.find_by_sql(q)
  end

  def self.find_protected_for_editing(*args)
    raise ActiveRecord::RecordNotFound unless User.current_user.can_edit_messages?
    self.find_protected(*args)
  end


  # Protect private messages
  def self.find_protected(*args)
    r = self.find(*args)
    return r.show_message_to?(User.current_user)
  end
  
  def show_message_to?(user)
    raise ActiveRecord::RecordNotFound if user.nil? and self.private == 1
    raise ActiveRecord::RecordNotFound if self.draft == 1 and self.created_by != user
    raise ActiveRecord::RecordNotFound if self.homebase != Homebase.current_homebase
    return self
  end

end
