# Schema as of Fri Oct 06 12:31:46 CDT 2006 (schema version 37)
#
#  id                  :integer       not null
#  homebase_id         :integer       not null
#  created_by          :integer       
#  name                :string(255)   
#  description         :text          
#  description_html    :text          
#  country             :string(255)   
#  state               :string(255)   
#  city                :string(255)   
#  created_at          :datetime      
#  updated_at          :datetime      
#  updated_by          :integer       
#  private             :integer       default(0)
#  archived            :integer       default(0)
#  messages_count      :integer       default(0)
#  events_count        :integer       default(0)
#  access_logs_count   :integer       default(0)
#  first_event         :datetime      
#  permalink           :string(255)   
#  salted_password     :string(255)   
#  salt                :string(255)   
#  resources_count     :integer       default(0)
#  excerpt             :text          
#  excerpt_html        :text          
#

require_dependency "search"

class Project < ActiveRecord::Base  
  belongs_to               :homebase, :counter_cache => true
  belongs_to               :user, :foreign_key => "created_by"
  has_many                 :events, :order => "start_date ASC", :conditions => "start_date >= '#{Time.now.strftime("%Y-%m-%d")}'"
  has_many                 :past_events, :class_name => "Event", :order => "start_date DESC", :conditions => "start_date < '#{Time.now.strftime("%Y-%m-%d")}'"
  has_many                 :all_events, :class_name => "Event", :order => "start_date ASC"
  has_many                 :messages, :order => "created_at DESC"
  has_many                 :files, :class_name => "Resource"
  has_many                 :images, :class_name => "Image"
  has_and_belongs_to_many  :groups
  has_and_belongs_to_many  :addresses
  # has_and_belongs_to_many  :files, :class_name => "Resource"
  has_many                 :access_logs
  #has_many                 :unique_visitors, :class_name => "AccessLog", :finder_sql => "SELECT DISTINCT ON (ip) access_logs.* FROM access_logs WHERE access_logs.project_id = #{self.id}"

  # Docs: http://dema.ruby.com.br/files/taggable/doc/index.html
  acts_as_taggable
  
  use_permalink :name
  # validates_uniqueness_of :permalink, :scope => :homebase_id
  # validates_presence_of :permalink
  
  
  
  validates_presence_of :name
  validates_presence_of :password, 
                        :on => :save, 
                        :message => "can't be blank if you select the <strong>private</strong> option.",
                        :if => Proc.new { |p| p.private? and p.salted_password.nil? }
  
  searches_on :all
  
  before_save :transform_description
  
  
  attr_accessor :resend_email
  attr_accessor :resend_email_unsent_only
  
  def transform_description
    self.description_html = RedCloth.new(self.description, [:hard_breaks] ).to_html unless self.description.nil?
    self.excerpt_html = RedCloth.new(self.excerpt, [:hard_breaks] ).to_html unless self.excerpt.nil?
  end
  
  
  #
  # Password stuff
  attr_accessor :private_checkbox
  attr_accessor :password
  
  def self.authenticate(permalink, password, homebase_id=Homebase.current_homebase.id)
    return nil if password.blank?
    p = find(:first, :conditions => ["permalink = ? and homebase_id = ?", permalink, homebase_id])
    return nil if p.nil?
    p = find(:first, :conditions => ["permalink = ? and salted_password = ?", permalink, ActiveRecord::PasswordSystem.encrypt(password, p.salt)])
    return nil if p.nil?
    return p
  end

  def decrypted_password
    ActiveRecord::PasswordSystem.decrypt(self.salted_password, self.salt)
  end

  #def private
  #  return self.private? ? 1 : 0
  #end
  
  #def private?
  #  return true if self.salted_password
  #  return false
  #end
  
  
  
  
  #
  # Depreciated
  # Replaced by tags
  def self.find_received_projects
    q = ["select * from projects where (id IN (
            select project_id from groups_projects where group_id IN (
              select group_id from addresses_groups where address_id IN (
                select id from addresses where email IN (
                  select email from users where homebase_id = ? 
                )
              )
            )
          ) OR ( 
            id IN (
              select project_id from addresses_projects where address_id IN (
                select id from addresses where email IN (
                  select email from users where homebase_id = ? 
                )
              )
            )
          )) 
          AND projects.homebase_id != ?", Homebase.current_homebase.id, Homebase.current_homebase.id, Homebase.current_homebase.id]
          
    q[0] << " order by created_at DESC"
    self.find_by_sql(q)
  end
  
  def self.find_protected_for_editing(*args)
    raise ActiveRecord::RecordNotFound unless User.current_user.can_edit_projects?
    r = self.find_protected(*args)
    raise "This project is archived and can't be edited" if r.archived?
    return r
  end
  
  def self.find_protected(*args)
    r = self.find(*args)
    return r.show_project_to?(User.current_user)
  end
  
  # Filter through the conditions...
  # Owner of the project can always see it
  # Only the owner can see it if it's a draft (messages only)
  # raise ActiveRecord::RecordNotFound if self.draft == 1
  # Otherwise, if the user belongs to the homebase, they can see it. 
  # If not, then it's a public request, so check the privacy.
  # raise ActiveRecord::RecordNotFound if user? and self.homebase.id != user.homebase.id
  # If this request is coming from someone else's homebae, raise an error. 
  #raise ActiveRecord::RecordNotFound if User.current_user.homebase.id != Homebase.current_homebase.id
  # If all those checks pass, show the project.
  def show_project_to?(user=User.current_user)
    raise ActiveRecord::RecordNotFound if user.nil? and self.private?
    raise ActiveRecord::RecordNotFound if self.homebase.id != Homebase.current_homebase.id
    return self
  end
  
  
end
