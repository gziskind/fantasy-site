#! /usr/bin/env ruby

require 'trollop'
require 'dotenv/load'
require_relative '../model'
require_relative '../lib/standings_parser'

options = Trollop::options do
	opt :baseball_league, "Baseball League ID", :short => "b", :type => :int, :required => true
	opt :database, "Database", :default => "test_database"
	opt :db_host, "Database Host", :default => "localhost", :short => "h"
	opt :db_port, "Database Port", :default => 27017, :short => "P"
	opt :db_user, "Database User", :short => "u", :type => :string
	opt :db_password, "Database Password", :short => "p", :type => :string
end

YEAR = Time.now.year
DATABASE = options[:database]
DB_HOST = options[:db_host]
DB_PORT = options[:db_port]
DB_USER = options[:db_user]
DB_PASSWORD = options[:db_password]
BASEBALL_ID = options[:baseball_league]
COOKIE_STRING = ENV["COOKIE_STRING"]

parser = StandingsParser.new(COOKIE_STRING, YEAR)
connect DATABASE, DB_HOST, DB_PORT, DB_USER, DB_PASSWORD

parser.parse_roto(BASEBALL_ID) if (YEAR != Time.now.year || (Time.now.month >= 4 && Time.now.month <= 9))
