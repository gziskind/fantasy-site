#! /usr/bin/env ruby

require 'trollop'
require_relative '../model'
require_relative '../lib/scoreboard_parser'

options = Trollop::options do
	opt :year, "Year", :default => Time.now.year
	opt :espn_user, "ESPN User", :short => "U", :type => :string, :required => true
	opt :espn_password, "ESPN Password", :short => "w", :type => :string, :required => true
	opt :football_league, "Football League ID", :short => "f", :type => :int, :required => true
	opt :database, "Database", :default => "test_database"
	opt :db_host, "Database Host", :default => "localhost", :short => "h"
	opt :db_port, "Database Port", :default => 27017, :short => "P"
	opt :db_user, "Database User", :short => "u", :type => :string
	opt :db_password, "Database Password", :short => "p", :type => :string
	opt :full_season, "Full Season", :short => "s", :type => :boolean, :default => false
end

YEAR = options[:year]
ESPN_USER = options[:espn_user]
ESPN_PASSWORD = options[:espn_password]
FOOTBALL_ID = options[:football_league]
DATABASE = options[:database]
DB_HOST = options[:db_host]
DB_PORT = options[:db_port]
DB_USER = options[:db_user]
DB_PASSWORD = options[:db_password]
FULL_SEASON = options[:full_season]

parser = ScoreboardParser.new(ESPN_USER, ESPN_PASSWORD)
connect DATABASE, DB_HOST, DB_PORT, DB_USER, DB_PASSWORD

if(FULL_SEASON)
	13.times{|x|
		parser.parse_scoreboard(FOOTBALL_ID, YEAR, x+1)
	}
else
	parser.parse_scoreboard(FOOTBALL_ID, YEAR)
end
