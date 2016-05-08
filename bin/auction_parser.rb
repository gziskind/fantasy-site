#! /usr/bin/env ruby

require 'trollop'
require 'date'
require_relative '../model'
require_relative '../lib/espn_fantasy'

options = Trollop::options do
	opt :year, "Year", :default => Time.now.year
	opt :espn_user, "ESPN User", :short => "u", :type => :string, :required => true
	opt :espn_password, "ESPN Password", :short => "p", :type => :string, :required => true
	opt :baseball_league, "Baseball League ID", :short => "b", :type => :int
	opt :football_league, "Football League ID", :short => "f", :type => :int
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
FOOTBALL_ID = options[:football_league]
TEST_PAGE = options[:test]
DATABASE = options[:database]
DB_HOST = options[:db_host]
DB_PORT = options[:db_port]
DB_USER = options[:db_user]
DB_PASSWORD = options[:db_password]

TEST_FILE = "/tmp/auction_data.html"


def download_test_page 
	if !BASEBALL_ID.nil?
		baseball_url = EspnFantasy.get_baseball_draft_url(BASEBALL_ID, YEAR)

		response_body = EspnFantasy.get_page(baseball_url, ESPN_USER, ESPN_PASSWORD);
		File.open(TEST_FILE, 'w') { |file| file.write(response_body) }
	elsif !FOOTBALL_ID.nil?
		football_url = EspnFantasy.get_football_draft_url(FOOTBALL_ID, YEAR)

		response_body = EspnFantasy.get_page(football_url, ESPN_USER, ESPN_PASSWORD)
		File.open(TEST_FILE, "w") { |file| file.write(response_body) }
	else
		puts "Must specify football or baseball id"
	end
end

def parse_football_draft
	puts "Parsing #{YEAR} Football Draft"

	if(!TEST_PAGE)
		draft_data = EspnFantasy.get_football_draft_data(ESPN_USER, ESPN_PASSWORD, FOOTBALL_ID, YEAR)
	else
		puts "Reading from test file #{TEST_FILE}"
		if File.exists? TEST_FILE
			page = File.read(TEST_FILE)
			draft_data = EspnFantasy.parse_draft_data(page)
		else
			puts "Test file [#{TEST_FILE}] not found"
			Process.exit(0)
		end
	end

	verify_draft_data(draft_data)

	save_draft_data(draft_data, 'football')

	puts "Draft data for #{YEAR} saved."
end

def parse_baseball_draft
	puts "Parsing #{YEAR} Baseball Draft"

	if(!TEST_PAGE)
		draft_data = EspnFantasy.get_baseball_draft_data(ESPN_USER, ESPN_PASSWORD, BASEBALL_ID, YEAR)
	else
		puts "Reading from test file #{TEST_FILE}"
		if File.exists? TEST_FILE
			page = File.read(TEST_FILE)
			draft_data = EspnFantasy.parse_draft_data(page)
		else
			puts "Test file [#{TEST_FILE}] not found"
			Process.exit(0)
		end
	end

	verify_draft_data(draft_data)

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

def verify_draft_data(draft_data)
	if draft_data.nil?
		raise "Draft data invalid"
	end
end


if options[:download]
	download_test_page
else
	connect DATABASE, DB_HOST, DB_PORT, DB_USER, DB_PASSWORD
	if !BASEBALL_ID.nil?
		parse_baseball_draft
	elsif !FOOTBALL_ID.nil?
		parse_football_draft
	else
		puts "Must specify either a football or baseball league id"
	end
end
