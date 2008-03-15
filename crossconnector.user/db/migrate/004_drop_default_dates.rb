class DropDefaultDates < ActiveRecord::Migration
  def self.up
    
    STDERR.puts "Migrating to version 4..."
    
    execute "alter table addresses alter column created_at drop default"
    execute "alter table addresses_groups alter column created_at drop default"
    execute "alter table alerts alter column created_at drop default"
    execute "alter table comments alter column created_at drop default"
    execute "alter table events alter column created_at drop default"
    execute "alter table homebases alter column created_at drop default"
    execute "alter table invitations alter column created_at drop default"
    execute "alter table invitations alter column used_at drop default"
    execute "alter table invoices alter column created_at drop default"
    execute "alter table messages alter column created_at drop default"
    execute "alter table pages alter column created_at drop default"
    execute "alter table projects alter column created_at drop default"
    execute "alter table tools alter column created_at drop default"
    execute "alter table users alter column created_at drop default"
    
    STDERR.puts "End migrating to version 4..."
    
  end

  def self.down
    
    STDERR.puts "Migrating down from version 4..."
    
    execute "alter table addresses alter column created_at set default now()"
    execute "alter table addresses_groups alter column created_at set default now()"
    execute "alter table alerts alter column created_at set default now()"
    execute "alter table comments alter column created_at set default now()"
    execute "alter table events alter column created_at set default now()"
    execute "alter table homebases alter column created_at set default now()"
    execute "alter table invitations alter column created_at set default now()"
    execute "alter table invitations alter column used_at set default now()"
    execute "alter table invoices alter column created_at set default now()"
    execute "alter table messages alter column created_at set default now()"
    execute "alter table pages alter column created_at set default now()"
    execute "alter table projects alter column created_at set default now()"
    execute "alter table tools alter column created_at set default now()"
    execute "alter table users alter column created_at set default now()"
    
    STDERR.puts "End migrating down from version 4..."
  end
end
