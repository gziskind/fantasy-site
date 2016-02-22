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

def parse_scoreboard(matchup = nil)
	# Might need to consider following a redirect
	path = "http://games.espn.go.com/ffl/scoreboard?leagueId=#{FOOTBALL_ID}&seasonId=#{YEAR}"
	if matchup == nil
		puts "Parsing Football Scoreboard"
	else
		puts "Parsing Football Scoreboard for week #{matchup}"
		path += "&matchupPeriodId=#{matchup}"
	end

	response_body = EspnFantasy.get_page(path, ESPN_USER, ESPN_PASSWORD);
	html = Nokogiri::HTML(response_body);

	matchups = extract_matchups(html)
	week = extract_week(html)
	if !week.nil? && verify_scoreboard_data(matchups)
		puts "Scoreboard data valid [#{Time.now}]"
		save_scores(matchups, week)
	else
		puts "Scoreboard data Invalid [#{Time.now}]"
		puts matchups
		puts html if matchups.size == 0
	end
end

def extract_week(html)
	week_element = html.css '//em'

	if(week_element.length > 0) 
		match_data = week_element[0].content.match(/Week (\d+)/)

		if(!match_data.nil?)
			return match_data[1].to_i
		else
			match_data = week_element[0].content.match(/Round (\d+)/)
			puts "Playoff Round #{match_data[1]}" if !match_data.nil?
			return nil
		end
	else
		return nil
	end
end

def extract_matchups(html)
	matchups = []
	scoreboard_div = html.css('//div#scoreboardMatchups')

	if(scoreboard_div.length > 0) 
		matchup_elements = scoreboard_div[0].css("td/table[@class='ptsBased matchup']")
		matchup_elements.each {|matchup_element|
			matchup = {}
			name_elements = matchup_element.css("div[@class='name']/a")

			team_and_user = name_elements[0].attribute("title").content
			match_data = team_and_user.match(/.*\((.*, )?(.*)\)/)
			matchup[:user1] = match_data[2]

			team_and_user = name_elements[1].attribute("title").content
			match_data = team_and_user.match(/.*\((.*, )?(.*)\)/)
			matchup[:user2] = match_data[2]

			points_elements = matchup_element.css("td[@class~='score']")
			
			matchup[:points1] = points_elements[0].content
			matchup[:points2] = points_elements[1].content

			matchups.push(matchup)
		}
	else
		puts "Not scoreboard data found"
	end

	return matchups
end

def verify_scoreboard_data(scoreboard_data)
	valid = true

	if(scoreboard_data.size != 6)
		puts "Invalid matchup length"
		valid = false
	end

	fields = [:user1,:user2, :points1, :points2]
	scoreboard_data.each {|matchup|
		fields.each{ |field|
			if matchup[field].nil?
				valid = false
			end
		}
	}

	return valid;
end

def save_scores(matchup_data, week)
	season = Season.find_by_sport_and_year('football', YEAR)

	week_result = WeekResult.find_by_week_and_season_id(week, season._id)

	if(week_result.nil?)
		matchups = []
		matchup_data.each{|matchup_data|
			user1 = User.find_by_unique_name(matchup_data[:user1]);
			user2 = User.find_by_unique_name(matchup_data[:user2]);

			result1 = TeamResult.new({points: matchup_data[:points1], user: user1})
			result2 = TeamResult.new({points: matchup_data[:points2], user: user2})

			matchups.push(Matchup.new(team_results:[result1, result2]))
		}
		
		season.week_results.push(WeekResult.new({week: week, matchups: matchups}))
		season.save!
	else
		week_result.week = week
		week_result.matchups.each_with_index {|matchup, index|
			user1 = User.find_by_unique_name(matchup_data[index][:user1]);
			user2 = User.find_by_unique_name(matchup_data[index][:user2]);

			matchup.team_results[0].points = matchup_data[index][:points1]
			matchup.team_results[0].user = user1

			matchup.team_results[1].points = matchup_data[index][:points2]
			matchup.team_results[1].user = user2
		}

		week_result.save!
	end
end

connect DATABASE, DB_HOST, DB_PORT, DB_USER, DB_PASSWORD

if(FULL_SEASON)
	13.times{|x|
		parse_scoreboard(x+1)
	}
else
	parse_scoreboard
end
