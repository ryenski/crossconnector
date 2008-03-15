class AddTags < ActiveRecord::Migration
  def self.up    
    STDERR.puts "Migrating to version 10..."    
    
    STDERR.print "Creating tables: tags"
    create_table "tags", :force => true do |t|
      t.column "name", :string
    end
    
    STDERR.print ", tags_messages"
    create_table "tags_messages", :id => false, :force => true do |t|
      t.column "tag_id", :integer
      t.column "message_id", :integer
    end
    
    STDERR.print ", tags_projects"
    create_table "tags_projects", :id => false, :force => true do |t|
      t.column "tag_id", :integer
      t.column "project_id", :integer
    end
    
    STDERR.print ", tags_tools"
    create_table "tags_tools", :id => false, :force => true do |t|
      t.column "tag_id", :integer
      t.column "tool_id", :integer
    end

    STDERR.puts "\ndone."
  end

  def self.down
    STDERR.print "Migrating down from version 10... "
    drop_table "tags"
    drop_table "tags_messages"
    drop_table "tags_projects"
    drop_table "tags_tools"
    STDERR.puts "done."
  end
end
