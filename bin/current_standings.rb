#! /usr/bin/env ruby

require 'net/http'
require 'httparty'
require 'nokogiri'
require 'trollop'
require_relative '../model'

options = Trollop::options do
	opt :year, "Year", :default => Time.now.year
end

YEAR = options[:year]

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

def extract_team_baseball_info(html)
	extract_team_info html, false
end

def extract_team_football_info(html)
	extract_team_info html, true
end

def extract_team_info(html, is_football = false)
	teams = html.css "//table[@class='tableBody'][1]/tr/td/a"

	team_info = []
	teams.each {|team|
		match_data  = team['title'].match(/.*\((.*, )?(.*)\)/)

		team_info.push({
			team_name: team.content,
			owner: match_data[2]
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
		secondary_table = html.css("//table[@class='tableBody']")[1]
		if !secondary_table.nil?
			points = secondary_table.css("/tr/td[2]")
			points.each_with_index {|point,index|
				if index > 0
					team_info[index-1][:points] = point.content
				end
			}
		end
	end

	return team_info
end

def save_standings_baseball(league_name, info)
	save_standings league_name, info, "baseball"
end

def save_standings_football(league_name, info)
	save_standings league_name, info, "football"
end

def save_standings(league_name, info, sport)
	result_class = FootballResult
	result_class = BaseballResult if sport == 'baseball'

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
		result_data[:points] = team[:points] if !team[:points].nil?
		results.push(result_class.new(result_data));
	}

	season_data = {
		year: YEAR,
		sport: sport,
		league_name: league_name,
		results: results
	}
	season = Season.find_by_sport_and_year sport, YEAR
	season.destroy if(!season.nil?)

	season = Season.new(season_data);

	season.save!
end

def save_team_names_baseball(info)
	save_team_names info, 'baseball'
end

def save_team_names_football(info)
	save_team_names info, 'football'
end

def save_team_names(info, sport) 
	info.each {|team|
		owner = User.find_by_name(team[:owner]);

		current_team_name = TeamName.find_by_name_and_sport(team[:team_name], sport)
		if(!owner.nil? && (current_team_name.nil? || current_team_name.owner.name != team[:owner]))
			team_name = TeamName.new({
				owner: owner,
				name: team[:team_name],
				sport: sport,
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

def verify_team_baseball_info(info)
	verify_team_info info, 'baseball'
end

def verify_team_football_info(info)
	verify_team_info info, 'football'
end

def verify_team_info(info, sport) 
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

def parse_baseball
	puts "Parsing #{YEAR} Baseball Standings"
	response_body = query_espn_baseball;
	html = Nokogiri::HTML(response_body);
	league_name = extract_league_name html;
	team_info = extract_team_baseball_info html

	if verify_team_baseball_info(team_info)
		puts "Team info valid [#{Time.now}]"
		save_standings_baseball league_name, team_info
		save_team_names_baseball team_info
	else
		puts "Team info Invalid [#{Time.now}]"
		puts team_info
	end
end

def parse_football
	puts "Parsing #{YEAR} Football Standings"
	response_body = query_espn_football;
	html = Nokogiri::HTML(response_body);
	league_name = extract_league_name html;
	team_info = extract_team_info html, true

	if verify_team_football_info(team_info)
		puts "Team info valid [#{Time.now}]"
		save_standings_football league_name, team_info
		save_team_names_football team_info
	else
		puts "Team info Invalid [#{Time.now}]"
		puts team_info
	end
end

production_connect

parse_football if (YEAR != Time.now.year || (Time.now.month >= 9 && Time.now.month <= 12))
parse_baseball if (YEAR != Time.now.year || (Time.now.month >= 4 && Time.now.month <= 9))