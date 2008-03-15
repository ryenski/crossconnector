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

class Image < Resource
  validates_file_format_of :file, :in => ["gif", "png", "jpg", "GIF", "PNG", "JPG"]
  # validates_filesize_of :file, :in => 0..1.megabytes, :message => "is too large. Images must be 10 Megabytes or smaller."
  
  file_column :file, 
              :root_path => App::CONFIG[:app_ftp_root], 
              :store_dir => :store_dir_method, 
              :magick => {:versions => {
                  :thumb => {:size => "80x80"},
                  :screen => {:size => "480>x500>"}
              }}
  
  def store_dir_method
    "#{Homebase.current_homebase.subdomain}/images" unless Homebase.current_homebase.nil?
  end
end
