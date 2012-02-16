$:.unshift(File.dirname(__FILE__) + "/../lib")
ENV["RAILS_ENV"] = "test"

require "rubygems"
require "bundler/setup"
require "rspec"
require "logger"
require "sequel"

DB = case ENV["DB"]
when "mysql"
  begin
    Sequel.connect :adapter => "mysql2", :database => "delayed_jobs", :test => true
  rescue Sequel::DatabaseConnectionError
    system "mysql -e 'CREATE DATABASE IF NOT EXISTS `delayed_jobs` DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_unicode_ci'"
    retry
  end
when "postgres"
  begin
    Sequel.connect :adapter => "postgres", :database => "delayed_jobs", :test => true
  rescue Sequel::DatabaseConnectionError
    system "createdb --encoding=UTF8 delayed_jobs"
    retry
  end
else
  Sequel.sqlite
end

DB.drop_table :delayed_jobs rescue Sequel::DatabaseError
DB.drop_table :stories rescue Sequel::DatabaseError

DB.create_table :delayed_jobs do
  primary_key :id
  Integer :priority, :default => 0
  Integer :attempts, :default => 0
  String  :handler, :text => true
  String  :last_error, :text => true
  Time    :run_at
  Time    :locked_at
  Time    :failed_at
  String  :locked_by
  String  :queue
  Time    :created_at
  Time    :updated_at
  index   [:priority, :run_at]
end
DB.create_table :stories do
  primary_key :story_id
  String      :text
  TrueClass   :scoped, :default => true
end

require "delayed_job_sequel"
require "delayed/backend/shared_spec"

Delayed::Worker.logger = Logger.new("/tmp/dj.log")
DB.logger = Delayed::Worker.logger

# Purely useful for test cases...
class Story < Sequel::Model
  def tell; text; end
  def whatever(n, _); tell*n; end
  def update_attributes(*args)
    update *args
  end
  handle_asynchronously :whatever
end
