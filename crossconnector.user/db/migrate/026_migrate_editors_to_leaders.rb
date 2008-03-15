class MigrateEditorsToLeaders < ActiveRecord::Migration
  def self.up
    STDERR.puts "Migrating to version 26."
    User.transaction do
      STDERR.puts "Changing Editors to Leaders..."
      execute "UPDATE USERS SET TYPE = 'Leader' WHERE TYPE = 'Editor'" rescue STDERR.puts "failed"
      STDERR.puts "done"
    end
  end

  def self.down
    STDERR.puts "Migrating down from version 26."
    User.transaction do
      STDERR.puts "Changing Leaders to Editors..."
      execute "UPDATE USERS SET TYPE = 'Editor' WHERE TYPE = 'Leader'"
      STDERR.puts "done"
    end
  end
end
