# Schema as of Fri Oct 06 12:31:46 CDT 2006 (schema version 37)
#
#  id                  :integer       not null
#  name                :string(255)   
#  caption             :string(255)   
#  description         :string(255)   
#  thumbnail           :string(255)   
#  image               :string(255)   
#  movie               :string(255)   
#  created_at          :string(255)   
#

class Screenshot < ActiveRecord::Base
  
  file_column :image, :root_path => App::CONFIG[:app_ftp_root], :store_dir => :store_dir_method
  file_column :movie, :root_path => App::CONFIG[:app_ftp_root], :store_dir => :store_dir_method
  file_column :thumbnail, :root_path => App::CONFIG[:app_ftp_root], :store_dir => :store_dir_method
  
  def store_dir_method
    File.join(App::CONFIG[:app_ftp_root], "www")
  end
  
end
