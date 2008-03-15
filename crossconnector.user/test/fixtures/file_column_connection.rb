print "Using native PostgreSQL\n"
require 'logger'

ActiveRecord::Base.logger = Logger.new("debug.log")

db = 'file_column_test'

ActiveRecord::Base.establish_connection(
  :adapter  => "postgresql",
  :host     => "localhost",
  :username => "ryenski",
  :password => "",
  :database => db
)
