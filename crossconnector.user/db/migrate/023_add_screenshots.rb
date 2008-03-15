class AddScreenshots < ActiveRecord::Migration
  def self.up

    STDERR.puts "Migrating to version 23... "
    
    create_table "screenshots", :force => true do |t|
      t.column "name", :string
      t.column "caption", :string
      t.column "description", :string
      t.column "thumbnail", :string
      t.column "image", :string
      t.column "movie", :string
      t.column "created_at", :string
    end
    
    STDERR.puts "done "
    
  end

  def self.down
    
    STDERR.puts "Migrating down from version 23... "
    
    drop_table "screenshots"
    
    STDERR.puts "done"
  end
end
