#! /usr/bin/env ruby

require 'net/http'
require 'httparty'
require 'nokogiri'
require 'trollop'
require 'date'
require_relative '../model'
require_relative '../lib/espn_fantasy'

options = Trollop::options do
	opt :espn_user, "ESPN User", :short => "U", :type => :string, :required => true
	opt :espn_password, "ESPN Password", :short => "w", :type => :string, :required => true
	opt :baseball_league, "Baseball League ID", :short => "b", :type => :int, :required => true
	opt :database, "Database", :default => "test_database"
	opt :db_host, "Database Host", :default => "localhost", :short => "h"
	opt :db_port, "Database Port", :default => 27017, :short => "P"
	opt :db_user, "Database User", :short => "u", :type => :string
	opt :db_password, "Database Password", :short => "p", :type => :string
end

YEAR = Time.now.year
DATABASE = options[:database]
DB_HOST = options[:db_host]
DB_PORT = options[:db_port]
DB_USER = options[:db_user]
DB_PASSWORD = options[:db_password]
ESPN_USER = options[:espn_user]
ESPN_PASSWORD = options[:espn_password]
BASEBALL_ID = options[:baseball_league]

ORDER =["C","1B","2B","SS","3B","OF","DH","SP","RP"]

def parse_roto
	puts "Parsing #{YEAR} Baseball Roto Stats"

	baseball_url = "http://games.espn.go.com/flb/standings?leagueId=#{BASEBALL_ID}&seasonId=#{YEAR}"

	response_body = EspnFantasy.get_page(baseball_url, ESPN_USER, ESPN_PASSWORD);
	html = Nokogiri::HTML(response_body);

	stats = parse_roto_data(html)
	calculate_points(stats)
end

def parse_roto_data(html)
	teams = html.css "//table[@id='statsTable']/tr[@class='tableBody sortableRow']"
	
	parse_teams(teams)
end

def parse_teams(teams)
	stats = []

	teams.each {|team|
		stat_line = team.css('td')

		name = extract_user(stat_line[1].css('a')[0])
		user = User.find_by_unique_name(name.to_s);

		stat = RotoStat.find_by_name(user.name)
		stat = RotoStat.new if stat.nil?

		stat.name = user.name
		stat.runs = stat_line[3].content
		stat.homeruns = stat_line[4].content
		stat.rbi = stat_line[5].content
		stat.sb = stat_line[6].content
		stat.average = stat_line[7].content
		stat.ops = stat_line[8].content
		stat.quality_starts = stat_line[10].content
		stat.wins = stat_line[11].content
		stat.saves = stat_line[12].content
		stat.era = stat_line[13].content
		stat.whip = stat_line[14].content
		stat.k_per_9 = stat_line[15].content

		stats.push(stat)
	}

	stats
end

def calculate_points(stats)
	runs_points = calculate_points_from_stat(stats, 'runs')
	homeruns_points = calculate_points_from_stat(stats, 'homeruns')
	rbi_points = calculate_points_from_stat(stats, 'rbi')
	sb_points = calculate_points_from_stat(stats, 'sb')
	average_points = calculate_points_from_stat(stats, 'average')
	ops_points = calculate_points_from_stat(stats, 'ops')
	quality_starts_points = calculate_points_from_stat(stats, 'quality_starts')
	wins_points = calculate_points_from_stat(stats, 'wins')
	saves_points = calculate_points_from_stat(stats, 'saves')
	era_points = calculate_points_from_stat(stats, 'era', true)
	whip_points = calculate_points_from_stat(stats, 'whip', true)
	k_per_9_points = calculate_points_from_stat(stats, 'k_per_9')

	stats.each{|stat|
		name = stat.name

		stat.runs_points = runs_points[name]
		stat.homeruns_points = homeruns_points[name]
		stat.rbi_points = rbi_points[name]
		stat.sb_points = sb_points[name]
		stat.average_points = average_points[name]
		stat.ops_points = ops_points[name]
		stat.quality_starts_points = quality_starts_points[name]
		stat.wins_points = wins_points[name]
		stat.saves_points = saves_points[name]
		stat.era_points = era_points[name]
		stat.whip_points = whip_points[name]
		stat.k_per_9_points = k_per_9_points[name]

		stat.total_points = runs_points[name] + homeruns_points[name] + rbi_points[name] + sb_points[name] + average_points[name] + ops_points[name] + quality_starts_points[name] + wins_points[name] + saves_points[name] + era_points[name] + whip_points[name] + k_per_9_points[name]

		stat.save!
	}
end

def calculate_points_from_stat(stats, stat_name, inverse = false)
	runs = {}
	run_points = {}
	stats.each {|stat|
		runs[stat[stat_name].to_s] = [] if runs[stat[stat_name].to_s].nil?
		runs[stat[stat_name].to_s].push(stat.name)
	}

	sorted_keys = runs.keys.sort {|run1,run2| 
		if(inverse)
			run2.to_f <=> run1.to_f
		else
			run1.to_f <=> run2.to_f
		end
	}

	value = 1
	sorted_keys.each{|sorted_key|
		names = runs[sorted_key]
		points = 0
		names.each{|name|
			points += value
			value += 1
		}
		points = points.to_f / names.length

		names.each{|name|
			run_points[name] = points
		}
	}

	run_points
end

def extract_user(a)
	team_and_user = a.attribute("title").content
	match_data = team_and_user.match(/.*\((.*)\)/)
	match_data[1]
end

connect DATABASE, DB_HOST, DB_PORT, DB_USER, DB_PASSWORD

parse_roto if (YEAR != Time.now.year || (Time.now.month >= 4 && Time.now.month <= 9))
