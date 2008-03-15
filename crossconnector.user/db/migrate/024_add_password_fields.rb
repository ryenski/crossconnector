class AddPasswordFields < ActiveRecord::Migration
  def self.up
    add_column "projects", "salted_password", :string
    add_column "projects", "salt", :string
    
    add_column "messages", "salted_password", :string
    add_column "messages", "salt", :string
    
    add_column "resources", "salted_password", :string
    add_column "resources", "salt", :string
    

    Project.update_all("private = 0", "private is null")
    Message.update_all("private = 0", "private is null")
    Resource.update_all("private = 0", "private is null")
    
  end

  def self.down
    remove_column "projects", "salted_password"
    remove_column "projects", "salt"

    remove_column "messages", "salted_password"
    remove_column "messages", "salt"

    remove_column "resources", "salted_password"
    remove_column "resources", "salt"

  end
end
