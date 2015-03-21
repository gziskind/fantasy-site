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
	opt :max_matchup_length, "Maximum Matchup League", :short => "m", :type => :int, :default => 21
	opt :number_of_matchups, "Number of matchups", :short => "n", :type => :int, :default => 24
	opt :all_stats, "Display Most and Least Stats", :short => "a", :type => :boolean, :default => false
end

YEAR = options[:year]
ESPN_USER = options[:espn_user]
ESPN_PASSWORD = options[:espn_password]
BASEBALL_ID = options[:baseball_league]
MAX_MATCHUP_LENGTH = options[:max_matchup_length]
NUMBER_OF_MATCHUPS = options[:number_of_matchups]
DISPLAY_ALL_STATS = options[:all_stats]

COUNTING = ["R","HR","RBI","SB","QS","W","SV"]
REVERSE_STATS = ["ERA","WHIP"]

def query_espn_baseball(matchup)
	hostname = "games.espn.go.com"
	query_espn "http://#{hostname}/flb/scoreboard?leagueId=#{BASEBALL_ID}&seasonId=#{YEAR}&matchupPeriodId=#{matchup}"
end

def query_espn(standings_uri)
	hostname = "r.espn.go.com"
	login_uri = "https://#{hostname}/espn/memberservices/pc/login"

	query_options = {
		"username" => ESPN_USER,
		"password" => ESPN_PASSWORD,
		"SUBMIT" => 1
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

def parse_baseball
	puts "Parsing #{YEAR} Baseball Scoreboards"
	season_stats = []

	for index in 1..NUMBER_OF_MATCHUPS
		puts "Parsing Week #{index}"
		response_body = query_espn_baseball(index);
		html = Nokogiri::HTML(response_body);

		matchup_length = extract_matchup_length html

		team_stats = extract_all_stats html
		season_stats.push({
			stats: team_stats,
			matchup_length: matchup_length
		})
	end

	compiled_stats = compile_stats season_stats

	display_results(compiled_stats)
end

def extract_matchup_length(html)
	dates = html.css "//em"

	match_data = dates[0].content.match(/.*\(((.*) - (.*))\)/)

	date1 = match_data[2]
	date2 = match_data[3]

	days = 
	if(is_number?(date2)) 
		days = date2.to_i - Date.parse(date1).day
	else
		days = Date.parse(match_data[3]).mjd - Date.parse(match_data[2]).mjd
	end

	return days + 1
end

def is_number?(string)
	true if Float(string) rescue false
end


def display_results(stats) 
	if(DISPLAY_ALL_STATS)
		puts "Most Weekly Stats"
		stats[:maximums].each {|stat, info|
			display_stat_line(stat, info)
		}
		
		puts ""
		puts "Least Weekly Stats"
		stats[:minimums].each {|stat, info|
			display_stat_line(stat, info)
		}
	else
		puts "Best Weekly Stats"
		stats[:maximums].each {|stat, info|
			display_stat_line(stat, info) if !REVERSE_STATS.include? stat
		}
		
		stats[:minimums].each {|stat, info|
			display_stat_line(stat, info) if REVERSE_STATS.include? stat
		}
	end
end

def display_stat_line(stat, info)
	puts "#{stat} -- #{info[:value]} -- Week #{info[:week]} -- #{info[:user]} -- Matchup Length #{info[:matchup_length]}"
end


def compile_stats(stats)
	minimums = {}
	maximums = {}

	stats.each_with_index {|stat_info, week_index|
		matchup_length = stat_info[:matchup_length]
		weekly_stat = stat_info[:stats]

		weekly_stat.each{|user,stat_line|
			stat_line.each {|stat, value|

				if(matchup_length <= MAX_MATCHUP_LENGTH  || !COUNTING.include?(stat))

					if(minimums[stat].nil? || minimums[stat][:value] > value.to_f)
						minimums[stat] = {
							user: user,
							value: value.to_f,
							week: week_index + 1,
							matchup_length: matchup_length
						}
					elsif(minimums[stat][:value] == value.to_f)
						current_user = minimums[stat][:user]
						current_week = minimums[stat][:week]

						minimums[stat][:user] = "#{current_user}, #{user}"
						minimums[stat][:week] = "#{current_week}, #{week_index + 1}"
					end

					if(maximums[stat].nil? || maximums[stat][:value] < value.to_f)
						maximums[stat] = {
							user: user,
							value: value.to_f,
							week: week_index + 1,
							matchup_length: matchup_length
						}
					elsif(maximums[stat][:value] == value.to_f)
						current_user = maximums[stat][:user]
						current_week = maximums[stat][:week]

						maximums[stat][:user] = "#{current_user}, #{user}"
						maximums[stat][:week] = "#{current_week}, #{week_index + 1}"
					end
				end
			}
		}
	}

	{
		minimums: minimums,
		maximums: maximums
	}
end

def extract_all_stats(html) 
	stats = {}
	teams = html.css "//table[@class='tableBody'][1]/tr[@class='linescoreTeamRow']"

	base_stats = extract_base_stats(html)

	teams.each {|team|
		user = extract_user(team)

		stats[user] = extract_stats(base_stats, team)
	}

	stats
end	

def extract_base_stats(html)
	base_stats = []
	base_stats_data = html.css "//table[@class='tableBody'][1]/tr[@class='tableSubHead'][2]/th"

	for index in 1..12
		base_stats.push(base_stats_data[index].content);
	end

	base_stats
end

def extract_user(team)
	a = team.css("td/a")[0]
	team_and_user = a.attribute("title").content
	match_data = team_and_user.match(/.*\((.*)\)/)
	match_data[1]
end

def extract_stats(base_stats, team)
	stats = team.css("td:not(.sectionLeadingSpacer)").css("td:not(.teamName)")
	stats_hash = {}

	for index in 1..12
		stats_hash[base_stats[index-1]] = stats[index-1].content;
	end

	stats_hash
end

parse_baseball