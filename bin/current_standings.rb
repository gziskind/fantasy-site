#! /usr/bin/env ruby

require 'net/http'
require 'httparty'
require 'nokogiri'
require 'trollop'
require_relative '../model'

options = Trollop::options do
	opt :year, "Year", :default => Time.now.year
	opt :database, "Database", :default => "test_database"
	opt :db_host, "Database Host", :default => "localhost", :short => "h"
	opt :db_port, "Database Port", :default => 27017, :short => "P"
	opt :db_user, "Database User", :short => "u", :type => :string
	opt :db_password, "Database Password", :short => "p", :type => :string
	opt :espn_user, "ESPN User", :short => "U", :type => :string, :required => true
	opt :espn_password, "ESPN Password", :short => "w", :type => :string, :required => true
	opt :baseball_league, "Baseball League ID", :short => "b", :type => :int, :required => true
	opt :football_league, "Football League ID", :short => "f", :type => :int, :required => true
end

YEAR = options[:year]
DATABASE = options[:database]
DB_HOST = options[:db_host]
DB_PORT = options[:db_port]
DB_USER = options[:db_user]
DB_PASSWORD = options[:db_password]
ESPN_USER = options[:espn_user]
ESPN_PASSWORD = options[:espn_password]
BASEBALL_ID = options[:baseball_league]
FOOTBALL_ID = options[:football_league]


def query_espn_baseball
	hostname = "games.espn.go.com"
	query_espn "http://#{hostname}/flb/standings?leagueId=#{BASEBALL_ID}&seasonId=#{YEAR}"
end

def query_espn_football
	hostname = "games.espn.go.com"
	query_espn "http://#{hostname}/ffl/standings?leagueId=#{FOOTBALL_ID}&seasonId=#{YEAR}"
end

def query_espn(standings_uri)
	hostname = "r.espn.go.com"
	login_uri = "https://#{hostname}/members/util/loginUser"

	query_options = {
		"username" => ESPN_USER,
		"password" => ESPN_PASSWORD
	}

	cookie_header = nil

	request = Net::HTTP::Post.new(login_uri)
	request.form_data = query_options
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

	cookies = ['BLUE','espnAuth={','SWID={']
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

	name[1].content.sub /(\s(\d{4}) Regular Season Final)? Standings/,""
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
			team_points_hash = {}

			team_names = secondary_table.css("/tr/td[1]/a[1]")
			points = secondary_table.css("/tr/td[2]")
			points.each_with_index {|point,index|
				if index > 0
					team_points_hash[team_names[index-1].content] = point.content
				end
			}

			team_info.each {|info|
				info[:points] = team_points_hash[info[:team_name]];
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
		user = User.find_by_unique_name(team[:owner]);

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
	if !season.nil?
		season.results.each {|result|
			result.destroy
		}
		season.destroy
	end

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
		owner = User.find_by_unique_name(team[:owner]);

		current_team_name = TeamName.find_by_name_and_sport(team[:team_name], sport)
		if(!owner.nil? && (current_team_name.nil? || current_team_name.owner.unique_name != team[:owner]))
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
			current_team_name.save!
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

connect DATABASE, DB_HOST, DB_PORT, DB_USER, DB_PASSWORD

parse_football if (YEAR != Time.now.year || (Time.now.month >= 9 && Time.now.month <= 12))
parse_baseball if (YEAR != Time.now.year || (Time.now.month >= 4 && Time.now.month <= 9))