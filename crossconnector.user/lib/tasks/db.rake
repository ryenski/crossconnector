#pg_restore --dbname=crossconnector_dev --clean --format=t --user=ryenski ~/Desktop/crossconnector.dump.sql.tar 

ENV['USER']     = "lighttpd" unless ENV['USER']
ENV['DB_NAME']  = RAILS_ENV == "production" ? "crossconnector_production" : "crossconnector_dev" unless ENV['DB_NAME']
ENV['DB_FILE']  = "#{ENV['DB_NAME']}_backup.sql.tar" unless ENV['DB_FILE']
ENV['DB_PATH']  = File.join("db", ENV['DB_FILE']) unless ENV['DB_PATH']
ENV['DB_USER']  = RAILS_ENV == "production" ? "postgres" : "ryenski" unless ENV['DB_USER'] 

namespace :db do
  desc "Purges the database and imports pg_dump from the live server."
  task(:import_live) do
    dbfile = "~/Desktop/crossconnector.dump.sql.tar"
    username = "ryenski"
    dbname = "crossconnector_dev"
    command = "pg_restore --dbname=#{ENV['DB_NAME']} --clean --format=t --user=#{ENV['DB_USER']} #{ENV['DB_FILE']}" rescue "Unable to complete command"
    system command
  end
  
  desc "Backs up the database using pg_dump. Puts the file in db/DBNAME_backup.sql.tar"
  task(:pg_dump) do
    command = "pg_dump --file=#{ENV['DB_PATH']} --no-owner --oids --format=t --user=#{ENV['DB_USER']} #{ENV['DB_NAME']}"
    system command
  end
  
  desc "Restore the database using pg_restore. Looks for the backup file in db/DBNAME_backup.sql.tar"
  task(:pg_restore) do
    command = "pg_restore --dbname=#{ENV['DB_NAME']} --clean --no-owner --format=t --user=#{ENV['DB_USER']} #{ENV['DB_PATH']}" 
    system command
    puts "#{ENV['DB_NAME']} restored from #{ENV['DB_PATH']}"
  end
  
  # http://www.cpqlinux.com/sshcopy.html
  desc "Download the database backup file"
  task(:download) do
    command = %Q{ssh -l #{USER} crossconnector.org cat "<" /srv/app/crossconnector/#{ENV['DB_PATH']}.gz | gunzip > #{ENV['DB_PATH']}}
    system command
  end
  
  desc "Back up the database using pg_dumpall"
  task(:pg_dumpall) do
    command = %Q{pg_dumpall > /Volumes/MirrorDisk/etc/AppDB/backup}
  end
  
end