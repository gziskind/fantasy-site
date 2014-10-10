#! /usr/bin/env ruby

require 'net/http'
require 'httparty'
require 'nokogiri'
require_relative '../model'

YEAR = 2014

def query_espn_baseball
	hostname = "games.espn.go.com"
	query_espn "http://#{hostname}/flb/standings?leagueId=33843&seasonId=#{YEAR}"
end

def query_espn_football
	hostname = "games.espn.go.com"
	query_espn "http://#{hostname}/ffl/standings?leagueId=196185&seasonId=#{YEAR}"
end

def query_espn(standings_uri)
	hostname = "r.espn.go.com"
	login_uri = "https://#{hostname}/espn/memberservices/pc/login"

	options = {
		"username" => "gziskind",
		"password" => "kaplacko",
		"SUBMIT" => 1
	}

	cookie_header = nil

	request = Net::HTTP::Post.new(login_uri)
	request.form_data = options
	Net::HTTP::start(hostname, 443, :use_ssl => true) { |http|
		http.use_ssl = true
		http.verify_mode = OpenSSL::SSL::VERIFY_NONE # read into this
		response = http.request(request);

		cookie_header = response['set-cookie']
	}

	cookie_string = parse_cookies(cookie_header)

	response = HTTParty.get(standings_uri, :headers => {"Cookie" => cookie_string});

	return response.body
end

def parse_cookies(cookie_header)
	match_data = cookie_header.scan(/\S+=\S+;/)
	cookie_string = ''

	cookies = ['BLUE','espnAuth','RED','SWID']
	match_data.each { |cookie|
		cookies.each {|name|
			if(cookie.start_with? name)
				cookie_string += cookie
			end
		}
	}

	cookie_string
end

def extract_league_name(html) 
	name = html.css "//h1";

	name[1].content
end

def extract_team_info(html, is_football = false)
	teams = html.css "//table[@class='tableBody'][1]/tr/td/a"

	team_info = []
	teams.each {|team|
		match_data  = team['title'].match(/.*\((.*)\)/)
		team_info.push({
			team_name: team.content,
			owner: match_data[1]
		})
	}

	wins = html.css "//table[@class='tableBody'][1]/tr/td[2]"
	wins.each_with_index {|win,index|
		if index > 0
			team_info[index-1][:wins] = win.content
		end
	}

	losses = html.css "//table[@class='tableBody'][1]/tr/td[3]"
	losses.each_with_index {|loss,index|
		if index > 0
			team_info[index-1][:losses] = loss.content
		end
	}

	ties = html.css "//table[@class='tableBody'][1]/tr/td[4]"
	ties.each_with_index {|tie,index|
		if index > 0
			team_info[index-1][:ties] = tie.content
		end
	}

	if is_football
		points = html.css("//table[@class='tableBody']")[1].css("/tr/td[2]")
		points.each_with_index {|point,index|
			if index > 0
				team_info[index-1][:points] = point.content
			end
		}
	end

	return team_info
end

def save_standings(league_name, info)
	production_connect

	results = [];
	info.each_with_index {|team, index|
		user = User.find_by_name(team[:owner]);

		result_data = {
			place: index + 1,
			team_name: team[:team_name],
			wins: team[:wins],
			losses: team[:losses],
			ties: team[:ties],
			user: user
		}
		results.push(BaseballResult.new(result_data));
	}

	season_data = {
		year: YEAR,
		sport: 'baseball',
		league_name: league_name,
		results: results
	}
	season = Season.find_by_sport_and_year "baseball", YEAR
	season.destroy if(!season.nil?)

	season = Season.new(season_data);

	season.save!
end

def save_team_names(info) 
	info.each {|team|
		owner = User.find_by_name(team[:owner]);

		current_team_name = TeamName.find_by_name_and_sport(team[:team_name], 'baseball')
		if(!owner.nil? && (current_team_name.nil? || current_team_name.owner.name != team[:owner]))
			team_name = TeamName.new({
				owner: owner,
				name: team[:team_name],
				sport: 'baseball',
			})

			if YEAR != Time.now.year
				team_name.year = YEAR;
			end

			puts "Adding team name [#{team[:team_name]}]"

			team_name.save!
		elsif owner.nil?
			puts "Could not find owner [#{team[:owner]}]"
		else
			puts "Team name [#{team[:team_name]}] already in database"
		end
	}
end

def verify_team_info(info) 
	valid = true

	if(info.length != 12)
		valid = false
	end

	fields = [:team_name, :owner, :wins, :losses, :ties]
	info.each {|entry|
		fields.each{ |field|
			if entry[field].nil?
				valid = false
			end
		}
	}

	return valid
end

response_body = query_espn_football;
html = Nokogiri::HTML(response_body);
league_name = extract_league_name html;
team_info = extract_team_info html, true

puts team_info
# response_body = query_espn_baseball
# html = Nokogiri::HTML(response_body)
# league_name = extract_league_name html;
# team_info = extract_team_info html

# if verify_team_info(team_info)
# 	puts "Team info valid [#{Time.now}]"
# 	save_standings league_name, team_info
# 	save_team_names team_info
# else
# 	puts "Team info Invalid [#{Time.now}]"
# 	puts team_info
# end
