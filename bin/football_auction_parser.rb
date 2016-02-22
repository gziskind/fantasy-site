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
	opt :football_league, "Football League ID", :short => "f", :type => :int, :required => true
end

YEAR = options[:year]
ESPN_USER = options[:espn_user]
ESPN_PASSWORD = options[:espn_password]
FOOTBALL_ID = options[:football_league]

ORDER = ["QB","RB","WR","TE"]

def parse_auction
	puts "Parsing #{YEAR} Football Draft"

	football_url = "http://games.espn.go.com/ffl/tools/draftrecap?leagueId=#{FOOTBALL_ID}&seasonId=#{YEAR}"

	response_body = EspnFantasy.get_page(football_url, ESPN_USER, ESPN_PASSWORD);
	html = Nokogiri::HTML(response_body);

	draft_data = extract_draft_data(html)
end

def extract_draft_data(html)
	teams = html.css "//table"
	draft_data = {}

	for index in 2..(teams.size - 1)
		get_draft_data_team(draft_data, teams[index])

	end
	
	display_draft_data draft_data
end

def display_draft_data(data)

	ORDER.each{|position|
		list = data[position]
		puts position

		list.sort_by! {|player| player[:amount]}
		list.reverse!

		list.each_with_index {|player,index|
			puts "#{index+1}. #{player[:amount]} -- #{player[:player]} -- #{player[:user]}"
		}
		puts
	}
end

def get_draft_data_team(draft_data, team)
	user_data = team.css "/tr[1]/td/a"
	user = extract_user user_data

	picks = team.css "tr[@class='tableBody']"
	picks.each {|pick|
		data = extract_pick_data pick

		draft_data[data[:position]] = [] if draft_data[data[:position]].nil?

		draft_data[data[:position]].push({
			player: data[:name],
			amount: data[:amount].to_i,
			user: user
		})
	}
end

def extract_pick_data(pick)
	dollar = pick.css("/td[3]")[0].content
	dollar[0] = ''
	player = pick.css("/td[2]")[0].content

	name, position = parse_player(player)

	{
		name: name,
		position: position,
		amount: dollar
	}
end

def parse_player(player)
	match_data = player.match(/(.*)[,]\s\w*.(\w*)/);

	return match_data[1], match_data[2]
end

def extract_user(a)
	team_and_user = a.attribute("title").content
	match_data = team_and_user.match(/.*\((.*)\)/)
	match_data[1]
end



parse_auction
