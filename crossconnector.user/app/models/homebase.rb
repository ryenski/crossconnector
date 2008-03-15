# Schema as of Fri Oct 06 12:31:46 CDT 2006 (schema version 37)
#
#  id                  :integer       not null
#  subscription_plan_id:integer       default(1)
#  subdomain           :string(255)   not null
#  name                :string(255)   not null
#  tagline             :string(255)   
#  profile             :text          
#  address1            :string(255)   
#  address2            :string(255)   
#  city                :string(255)   
#  state               :string(50)    
#  postal              :string(20)    
#  country             :string(255)   
#  time_zone           :string(255)   
#  phone               :string(20)    
#  website             :string(255)   
#  display_contact_info:integer       default(0)
#  created_at          :datetime      
#  updated_at          :datetime      
#  deleted             :integer       
#  deleted_at          :datetime      
#  created_by          :integer       
#  messages_count      :integer       default(0)
#  projects_count      :integer       default(0)
#  resources_count     :integer       default(0)
#  addresses_count     :integer       default(0)
#  groups_count        :integer       default(0)
#  access_logs_count   :integer       default(0)
#  logo                :string(255)   
#  profile_extended    :text          
#  free_trial          :integer       
#

require_dependency "search"

class Homebase < ActiveRecord::Base
  
  cattr_accessor :current_homebase
    
  belongs_to  :user, :foreign_key => "created_by"
  has_many    :leaders, :class_name => "Leader", :foreign_key => "homebase_id", :conditions => "deleted != 1", :dependent => true
  # Depreciated... 
  has_many    :editors, :class_name => "Editor", :foreign_key => "homebase_id", :conditions => "deleted != 1", :dependent => true

  has_many    :addresses, :dependent => true
  has_many    :groups, :dependent => true
  
  # Access Logs
  has_many    :access_logs, :dependent => true, :foreign_key => "public_homebase_id"
  
  # Message Associations
  has_many    :messages, :conditions => "draft != 1", :order => "created_at DESC, updated_at DESC", :dependent => true
  has_many    :all_messages, :class_name => "Message", :order => "created_at DESC, updated_at DESC", :dependent => true
  has_many    :public_messages, :class_name => "Message", :conditions => "private != 1 AND draft != 1", :order => "created_at DESC, updated_at DESC", :dependent => true
  
  
  # Project Associations
  has_many    :projects, :conditions => "archived != 1", :order => "first_event ASC, name ASC", :dependent => true
  has_many    :all_projects, :class_name => "Project", :order => "first_event ASC, name ASC", :dependent => true
  has_many    :public_projects, :class_name => "Project", :conditions => "private != 1 and archived != 1", :order => "first_event ASC, name ASC", :dependent => true
  has_many    :private_projects, :class_name => "Project", :conditions => "private = 1 and archived != 1", :order => "first_event ASC, name ASC", :dependent => true
  has_many    :archived_projects, :class_name => "Project", :conditions => "archived = 1", :order => "name ASC", :dependent => true
  has_many    :public_archived_projects, :class_name => "Project", :conditions => "private != 1 and archived = 1", :order => "name ASC", :dependent => true
  #has_many    :received_projects, :class_name => "Project", :finder_sql => ["select * from projects where (id IN (select project_id from groups_projects where group_id IN (select group_id from addresses_groups where address_id IN (select id from addresses where email IN (select email from users where homebase_id = ? )))) OR (id IN (select project_id from addresses_projects where address_id IN (select id from addresses where email IN (select email from users where homebase_id = ? ))))) AND projects.homebase_id != ?", Homebase.current_homebase.id, Homebase.current_homebase.id, Homebase.current_homebase.id]
  
  #File Associations
  has_many    :files, :class_name => "Resource", :order => "created_at DESC, updated_at DESC", :dependent => true
  has_many    :public_files, :class_name => "Resource", :conditions => "private != 1", :order => "created_at DESC, updated_at DESC", :dependent => true
  
  # Subscription
  has_one     :subscription
  belongs_to  :plan, :class_name => "SubscriptionPlan", :foreign_key => "subscription_plan_id"
  
  before_save :fix_url
  before_save :convert_subdomain_to_lower
  
  searches_on :name, :subdomain, :name, :profile, :profile_extended
  
  validates_file_format_of :logo, :in => ["gif", "png", "jpg"]
  validates_filesize_of :logo, :in => 0..100.kilobytes
  #validates_image_size :logo, :max
  
  file_column :logo, :magick => {:size => "500x10"}, :root_path => App::CONFIG[:app_ftp_root], :store_dir => :store_dir_method
  
  # Sets up the storage directory. 
  # Defaults to the users subdomain.  
  #def store_dir_method
  #  File.join(App::CONFIG[:app_ftp_root], Homebase.current_homebase.subdomain, "logo") unless Homebase.current_homebase.nil?
  #end
  def store_dir_method
    "#{Homebase.current_homebase.subdomain}/logo" unless Homebase.current_homebase.nil?
  end
  

  # Redefine find_by_subdomain to allow mixed case queries
  def find_by_subdomain(subdomain)  
    self.find_by_subdomain(subdomain.downcase)
  end
  
  def tags
    Tag.find_all
  end
  
  #
  # Depreciated
  # Don't use this anymore
  # Change subscription plans through the secure site
  # 
  def update_subscription_plan(to)
    self.update_attribute(:subscription_plan_id, to)
  end
  
  def fix_subscription
    plan = SubscriptionPlan.find_by_name("Free")
    self.subscription = Subscription.create(:homebase_id => self.id, :name => self.user.name, :price => 0, :email => self.user.email, :subscription_plan_id  => plan.id) if self.subscription.nil?
    self.subscription.update_attribute(:subscription_plan_id, plan.id) if subscription.plan.nil?
  end
  
  
  
  #
  # Figure out what date to start billing. 
  # This pretty much locks in a certain date on which all future bills 
  # will be charged. 
  # 
  def next_billing_date
    now = Time.now
    billing_day_of_month = self.created_at.day
    if now.day < billing_day_of_month
      # Bill this month
      billing_date = Time.mktime(now.year, now.month, billing_day_of_month)
    else
      # bill next month
      next_month = Time.now + 1.month
      billing_date = Time.mktime(next_month.year, next_month.month, billing_day_of_month)
    end
    return billing_date
  end
  
  
  def self.recent
    Homebase.count(:all, :conditions => ["created_at > ?", (Time.now - 1.week)])
  end
  
  def self.recent_month
    Homebase.count(["created_at > ?", (Time.now - 1.month)])
  end

  
  def total_files
    (self.files.count_by_sql("select sum(size) from resources where homebase_id = #{self.id}")).to_i
  end
  
  def available_storage
    ((self.subscription.plan.priveleges.find(2).plan_limit.to_i * 1000000) - self.total_files.to_i).to_i
  end
  
  def within_storage_limit?
    self.available_storage > 0
  end
  
  def within_projects_limit?
    limit = self.projects_limit
    return true if limit == 0
    return self.projects.count <= limit
  end
  
  def projects_limit
    self.subscription.plan.priveleges.find(1).plan_limit.to_i
  end
  
  def can_create_projects?
    return true if projects_limit == 0
    return true if self.projects.count < projects_limit
    return false
  end
  
  def web_address
    "http://#{self.subdomain}.#{App::CONFIG[:app_domain]}"
  end
  
    
  
  def convert_subdomain_to_lower
    self.subdomain = self.subdomain.downcase unless self.subdomain.blank?
  end
  
  def fix_url
    unless self.website.blank?
      self.website = "http://#{self.website}" unless self.website.include?("http://")
    end
  end
  
  #alias_column "account_address" => "subdomain"
  #alias_column "account_name" => "name"
  
  validates_presence_of     :name, :message => "can't be blank"
  validates_presence_of     :subdomain,                                           :message => "can't be blank"
  validates_length_of       :subdomain, :within => 1..40,                         :message => "is too long. Web addresses can't be longer than forty (40) characters"
  validates_length_of       :subdomain, :minimum => 2,                            :message => "is too short. Web addresses need to have at least two letters"
  validates_uniqueness_of   :subdomain,                                           :message => "is not available"
  validates_format_of       :subdomain, :with => /^\w*$/,                         :message => "is invalid. Web addresses can't contain spaces or punctuation marks"
  validates_exclusion_of    :subdomain, :in => App::CONFIG[:reserved_subdomains], :message => "is not available"
  validates_exclusion_of    :subdomain, :in => App::CONFIG[:banned_words],        :message => "contains a prohibited word"
  
  
end
