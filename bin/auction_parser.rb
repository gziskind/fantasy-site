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
end

YEAR = options[:year]
ESPN_USER = options[:espn_user]
ESPN_PASSWORD = options[:espn_password]
BASEBALL_ID = options[:baseball_league]
TEST_PAGE = options[:test]

TEST_FILE = "/tmp/auction_data.html"


def download_test_page 
	baseball_url = "http://games.espn.go.com/flb/tools/draftrecap?leagueId=#{BASEBALL_ID}&seasonId=#{YEAR}"

	response_body = EspnFantasy.get_page(baseball_url, ESPN_USER, ESPN_PASSWORD);
	File.open(TEST_FILE, 'w') { |file| file.write(response_body) }
end

def parse_draft
	puts "Parsing #{YEAR} Baseball Draft"

	baseball_url = "http://games.espn.go.com/flb/tools/draftrecap?leagueId=#{BASEBALL_ID}&seasonId=#{YEAR}"

	if(!TEST_PAGE)
		response_body = EspnFantasy.get_page(baseball_url, ESPN_USER, ESPN_PASSWORD);
	else
		puts "Reading from test file #{TEST_FILE}"
		response_body = File.read(TEST_FILE)
	end
	html = Nokogiri::HTML(response_body);

	draft_data = extract_draft_data(html)
end

def extract_draft_data(html)
	draft_type = get_draft_type(html)
	if(draft_type == :auction)
		puts "Parsing Auction Draft"
		extract_auction_data(html)
	elsif(draft_type == :snake)
		puts "Parsing Snake Draft"
		extract_snake_data(html)
	else
		puts "Could not determine draft type"
	end
end

def get_draft_type(html) 
	draft_info = html.css "//div[@class='games-alert-mod alert-mod2 games-grey-alert']"

	if(draft_info && draft_info.children.length >= 6)
		if(draft_info.children[5].content.include? "Auction")
			return :auction
		elsif(draft_info.children[5].content.include? "Snake")
			return :snake
		end
	end

	return nil
end


def extract_auction_data(html) 
	teams = html.css "//table"
	draft_data = []

	for index in 2..(teams.size - 1)
		get_draft_data_team(draft_data, teams[index])
	end
	
	save_draft_data draft_data
end

def save_draft_data(draft_data)
end

def get_draft_data_team(draft_data, team)
	user_data = team.css "/tr[1]/td/a"
	user = extract_user user_data

	picks = team.css "tr[@class='tableBody']"
	picks.each {|pick|
		data = extract_pick_data pick
		data[:user] = user
		draft_data.push(data)
	}
end

def extract_pick_data(pick)
	dollar = pick.css("/td[3]")[0].content
	dollar[0] = ''
	player = pick.css("/td[2]")[0].content
	pick_num = pick.css("/td[1]")[0].content
	keeper = is_keeper(pick)

	name, position = parse_player(player)

	{
		name: name,
		position: position,
		amount: dollar,
		pick: pick_num,
		keeper: keeper
	}
end

def is_keeper(pick)
	keeper = pick.css('/td[2]/span')[0]
	if(keeper)
		return true
	else
		return false
	end
end

def parse_player(player)
	match_data = player.match(/(.*)[,]\s\w*.(\w*).*(\w?)/);

	puts match_data
	return match_data[1].chomp("*"), match_data[2]
end

def extract_user(a)
	team_and_user = a.attribute("title").content
	match_data = team_and_user.match(/.*\((.*)\)/)
	match_data[1]
end


if options[:download]
	download_test_page
else
	parse_draft
end
