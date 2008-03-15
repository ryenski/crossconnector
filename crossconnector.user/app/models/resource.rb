# Schema as of Fri Oct 06 12:31:46 CDT 2006 (schema version 37)
#
#  id                  :integer       not null
#  homebase_id         :integer       not null
#  created_by          :integer       
#  name                :string(255)   
#  file                :string(255)   
#  description         :text          
#  content_type        :string(255)   
#  size                :integer       
#  data                :binary        
#  created_at          :datetime      
#  updated_at          :datetime      
#  updated_by          :integer       
#  private             :integer       default(0)
#  access_logs_count   :integer       default(0)
#  type                :string(20)    
#  permalink           :string(255)   
#  salted_password     :string(255)   
#  salt                :string(255)   
#  project_id          :integer       
#

class Resource < ActiveRecord::Base
  
  belongs_to :homebase, :counter_cache => true
  belongs_to :user
  belongs_to :project, :counter_cache => true
  has_many   :access_logs
  
  #has_and_belongs_to_many :messages
  #has_and_belongs_to_many :projects
  #has_and_belongs_to_many :addresses
  #has_and_belongs_to_many :groups
  
  # Activate Tagging
  acts_as_taggable 
  
  attr_accessor :password
  
  # Fix File Name
  before_save :fix_file_name
  def fix_file_name
    self[:file] = self.id.to_s if self[:file].nil?
    self.name = self[:file] if self.name.blank?
  end
  
  # Set up the Permalink
  use_permalink :name
  # validates_presence_of :file
  # validates_uniqueness_of :permalink, :scope => :homebase_id
  # validates_presence_of :permalink
  # validates_presence_of :name
  
  # Activate FileColumn
  #file_column :file, :store_dir => :store_dir_method
  #def store_dir_method
  #  File.join(App::CONFIG[:app_ftp_root], Homebase.current_homebase.subdomain, "files") unless Homebase.current_homebase.nil?
  #end
  
  # Activate FileColumn
  file_column :file, :root_path => App::CONFIG[:app_ftp_root], :store_dir => :store_dir_method, :fix_file_extensions => nil
    
  def store_dir_method
    "#{Homebase.current_homebase.subdomain}/files"
  end
  #def store_dir_method
  #  File.join(App::CONFIG[:app_ftp_root], Homebase.current_homebase.subdomain, "files") unless Homebase.current_homebase.nil?
  #end

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
  
  def private
    return self.private? ? 1 : 0
  end
  
  def private?
    return true if self.password? or self.project.password?
    return false
  end
  
  def self.find_received_files
    []
  end
  
  # PUBLIC-SIDE QUERIES  
  def self.find_public_files(limit="all", homebase=Homebase.current_homebase)
    conditions = ["private = 0 and homebase_id = ?", homebase.id]
    if limit == "all"
      self.find(:all, :conditions => conditions, :order => "created_at DESC") 
    else
      self.find(:all, :conditions => conditions, :limit => limit.to_i, :order => "created_at DESC")
    end
  end
  
  #def self.find_public_file(id)
  #  self.find(:first, :conditions => ["id = ? and private = 0 and homebase_id = ?", id, Homebase.current_homebase.id])
  #end
  
  #def self.find_my_files(limit="all")
    #conditions = ["created_by = ?", Homebase.current_homebase.id]
    #conditions[0] << " and private != 1" if User.current_user.nil?
    #self.find(:all, :order => "created_at DESC", :conditions => conditions)
    #self.find_by_sql(["select id, name, description, content_type, size, created_at, private, created_by from resources where created_by = ? order by created_at DESC", Homebase.current_homebase.id])
    
  #  conditions = ["homebase_id = ?", Homebase.current_homebase.id]
  #  if limit == "all"
  #    self.find(:all, :conditions => conditions, :order => "created_at DESC") 
  #  else
  #    self.find(:all, :conditions => conditions, :limit => limit.to_i, :order => "created_at DESC")
  #  end
  #end
  
  def self.find_protected(*args)
    r = self.find(*args.join(', '))
    return r.show_private_object_to(User.current_user)
  end
  
  # Protect private objects
  # Returns true or false
  # Syntax: requested_message.show_private_message_to(user_to_check)
  # To Do: Consolidate queries into a stored procedure? 
  # To Do: Make this into a module? 
  def show_private_object_to(user)
    return self if (self.private == 0) || (self.created_by.id == user.id)
    if self.private == 1 
      user_auth = User.find_by_sql(["select id,email from users where email IN (select addresses.email from addresses where addresses.id IN (select address_id from addresses_#{self.class}s where #{self.class}_id = ?)) AND email = ? limit 1", self.id, user.email ])
      group_auth = User.find_by_sql(["select id, email from users where email IN (select addresses.email from addresses where addresses.id IN (select address_id from addresses_groups where group_id = (select group_id from groups_#{self.class}s where #{self.class}_id = ? ))) AND email = ? LIMIT 1;", self.id, user.email])
      raise ActiveRecord::RecordNotFound if user_auth.empty? && group_auth.empty?
    end
    return self
  end
  
end
