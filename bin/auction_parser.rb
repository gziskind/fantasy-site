#! /usr/bin/env ruby

require 'net/http'
require 'httparty'
require 'nokogiri'
require 'trollop'
require 'date'
require_relative '../model'
require_relative '../lib/espn_fantasy'

options = Trollop::options do
	opt :year, "Year", :default => Time.now.year
	opt :espn_user, "ESPN User", :short => "u", :type => :string, :required => true
	opt :espn_password, "ESPN Password", :short => "p", :type => :string, :required => true
	opt :baseball_league, "Baseball League ID", :short => "b", :type => :int, :required => true
	opt :test, "Run against test page", :type => :boolean, :short => "t", :default => false
	opt :download, "Download test page", :type => :boolean, :short => "d", :default => false
	opt :database, "Database", :short => "D", :default => "test_database"
	opt :db_host, "Database Host", :default => "localhost", :short => "h"
	opt :db_port, "Database Port", :default => 27017, :short => "P"
	opt :db_user, "Database User", :short => "U", :type => :string
	opt :db_password, "Database Password", :short => "w", :type => :string
end

YEAR = options[:year]
ESPN_USER = options[:espn_user]
ESPN_PASSWORD = options[:espn_password]
BASEBALL_ID = options[:baseball_league]
TEST_PAGE = options[:test]
DATABASE = options[:database]
DB_HOST = options[:db_host]
DB_PORT = options[:db_port]
DB_USER = options[:db_user]
DB_PASSWORD = options[:db_password]

TEST_FILE = "/tmp/auction_data.html"


def download_test_page 
	baseball_url = EspnFantasy.get_baseball_draft_url(BASEBALL_ID, YEAR)

	response_body = EspnFantasy.get_page(baseball_url, ESPN_USER, ESPN_PASSWORD);
	File.open(TEST_FILE, 'w') { |file| file.write(response_body) }
end

def parse_draft
	puts "Parsing #{YEAR} Baseball Draft"

	if(!TEST_PAGE)
		draft_data = EspnFantasy.get_baseball_draft_data(ESPN_USER, ESPN_PASSWORD, BASEBALL_ID, YEAR)
	else
		puts "Reading from test file #{TEST_FILE}"
		page = File.read(TEST_FILE)
		draft_data = EspnFantasy.parse_baseball_draft_data(page)
	end

	save_draft_data(draft_data, 'baseball')

	puts "Draft data for #{YEAR} saved."
end

def save_draft_data(draft_data, sport)
	draft_data.each {|draft_pick_data|
		user = User.find_by_unique_name(draft_pick_data[:user]);

		first_name, last_name = parse_player_name(draft_pick_data[:name])


		player = Player.find_by_first_name_and_last_name(first_name, last_name)
		if(player.nil?)
			player = Player.new({
				first_name: first_name,
				last_name: last_name,
				sport: sport
			})

			player.save!
		end

		pick_conf = {
			position: draft_pick_data[:position],
			pick: draft_pick_data[:pick],
			keeper: draft_pick_data[:keeper],
			year: YEAR,
			sport: sport,
			user: user,
			player: player
		};

		pick_conf[:cost] = draft_pick_data[:amount] if !draft_pick_data[:amount].nil?

		draft_pick = DraftPick.new(pick_conf)

		draft_pick.save!
	}
end

def parse_player_name(name)
	match_data = name.match(/(.+)\s(.+)/)

	return match_data[1], match_data[2]
end


if options[:download]
	download_test_page
else
	connect DATABASE, DB_HOST, DB_PORT, DB_USER, DB_PASSWORD

	parse_draft
end
