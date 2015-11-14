#! /usr/bin/env ruby

require 'net/http'
require 'httparty'
require 'nokogiri'
require 'trollop'
require 'date'
require_relative '../model'

options = Trollop::options do
	opt :year, "Year", :default => Time.now.year
	opt :espn_user, "ESPN User", :short => "u", :type => :string, :required => true
	opt :espn_password, "ESPN Password", :short => "p", :type => :string, :required => true
	opt :baseball_league, "Baseball League ID", :short => "b", :type => :int, :required => true
end

YEAR = options[:year]
ESPN_USER = options[:espn_user]
ESPN_PASSWORD = options[:espn_password]
BASEBALL_ID = options[:baseball_league]

ORDER =["C","1B","2B","SS","3B","OF","DH","SP","RP"]

def query_espn_baseball
	hostname = "games.espn.go.com"
	query_espn "http://#{hostname}/flb/tools/draftrecap?leagueId=#{BASEBALL_ID}&seasonId=#{YEAR}"
end

def query_espn(standings_uri)
	login_uri = "https://registerdisney.go.com/jgc/v2/client/ESPN-ESPNCOM-PROD/guest/login?langPref=en-US"

	body = {
		loginValue: ESPN_USER,
		password: ESPN_PASSWORD
	}.to_json

	login_response = HTTParty.post(login_uri, body: body, headers: {'Content-type'=>'application/json'});

	login_swid = login_response['data']['token']['swid']
	cookie_string = "SWID=#{login_swid}; espnAuth={\"swid\":\"#{login_swid}\"};" 

	response = HTTParty.get(standings_uri, :headers => {"Cookie" => cookie_string});

	return response.body
end

def parse_auction
	puts "Parsing #{YEAR} Baseball Draft"

	response_body = query_espn_baseball;
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