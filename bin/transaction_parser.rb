#! /usr/bin/env ruby

require 'trollop'
require 'date'
require 'dotenv/load'

require_relative '../model'
require_relative '../lib/espn_fantasy'
require_relative '../lib/transaction_parser'

options = Trollop::options do
	opt :year, "Year", :default => Time.now.year
	opt :baseball_league, "Baseball League ID", :short => "b", :type => :int
	opt :football_league, "Football League ID", :short => "f", :type => :int
	opt :parse_file, "Parse draft from file", :type => :string, :short => "F"
	opt :database, "Database", :short => "D", :default => "test_database"
	opt :db_host, "Database Host", :default => "localhost", :short => "h"
	opt :db_port, "Database Port", :default => 27017, :short => "P"
	opt :db_user, "Database User", :short => "u", :type => :string
	opt :db_password, "Database Password", :short => "p", :type => :string
end

YEAR = options[:year]
BASEBALL_ID = options[:baseball_league]
FOOTBALL_ID = options[:football_league]
FILE = options[:parse_file]
DATABASE = options[:database]
DB_HOST = options[:db_host]
DB_PORT = options[:db_port]
DB_USER = options[:db_user]
DB_PASSWORD = options[:db_password]
COOKIE_STRING = ENV["COOKIE_STRING"]

parser = TransactionParser.new(COOKIE_STRING, YEAR)
connect DATABASE, DB_HOST, DB_PORT, DB_USER, DB_PASSWORD

parser.parse_football_transactions(FOOTBALL_ID) unless FOOTBALL_ID.nil?
parser.parse_baseball_transactions(BASEBALL_ID) unless BASEBALL_ID.nil?
