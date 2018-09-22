#! /usr/bin/env ruby

require 'net/http'
require 'httparty'
require 'nokogiri'
require 'trollop'
require 'date'
require 'dotenv/load'

require_relative '../model'
require_relative '../lib/espn_fantasy'

options = Trollop::options do
    opt :year, "Year", :default => Time.now.year
    opt :baseball_league, "Baseball League ID", :short => "b", :type => :int, :required => true
end

YEAR = options[:year]
BASEBALL_ID = options[:baseball_league]
COOKIE_STRING = ENV["COOKIE_STRING"]

SP_RP_MAP = {}
MATCHUP_DATA = {}
INNINGS_DECISIONS = {num:0}
SP_RP_DECISIONS = {num:0}

def parse_starts_per_matchup 
    exclude = [14]
    21.times {|matchup|
        if !exclude.include?(matchup+1)
            scoreboard_page = EspnFantasy.get_baseball_scoreboard_page(YEAR, BASEBALL_ID, COOKIE_STRING, matchup+1);

            html = Nokogiri::HTML(scoreboard_page);

            anchors = html.css "//table[@class='tableBody'][1]/tr/td/a"
            links = []
            anchors.each {|anchor|
                if anchor.content.include?("Full Box Score")
                    links.push(anchor.attribute('href'))
                end
            }

            links.each {|link|
                parse_matchup_page(link,matchup+1)
            }
        end
    }
    display_results(MATCHUP_DATA)
end

def parse_matchup_page(link, matchup_number)
    matchup_page = EspnFantasy.get_page("http://games.espn.com#{link}", COOKIE_STRING)

    html = Nokogiri::HTML(matchup_page)

    team_names = html.css "//td[@class=teamName]/a"
    tables1 = html.css "//table[@id=playertable_1]/tr[@class~=pncPlayerRow]"
    tables2 = html.css "//table[@id=playertable_3]/tr[@class~=pncPlayerRow]"

    total_starts = 0
    team_name = team_names[0].content
    tables1.each {|table|
        total_starts += get_player_starts(table, matchup_number, team_name)
    }
    set_total_starts(team_name, total_starts, matchup_number)

    total_starts = 0
    team_name = team_names[1].content
    tables2.each {|table|
        total_starts += get_player_starts(table, matchup_number, team_name)
    }
    set_total_starts(team_name, total_starts, matchup_number)
end

def set_total_starts(team, total_starts, matchup_number)
    if MATCHUP_DATA[team].nil?
        MATCHUP_DATA[team] = {}
    end

    MATCHUP_DATA[team][matchup_number] = total_starts
end

def display_results(data)
    total_average = 0
    start_counts = {}
    data.each {|key,value|
        team_average = 0
        puts "#{key} -"
        value.each {|week, count|
            puts " * week #{week} - #{count}"
            team_average += count
            increment_start_counts(start_counts, count)
        }
        team_average /= 20.0
        total_average += team_average
        puts "Average = #{team_average}"
        puts
    }
    total_average /= 12
    puts "Total average = #{total_average}"
    puts

    start_counts = Hash[ start_counts.sort_by { |key, val| key.to_s.to_i } ]
    start_counts.each{|start_count, count|
        puts "Number of #{start_count} starts: #{count}"
    }

    # puts "INNINGS_DECISIONS = #{INNINGS_DECISIONS}"
    # puts "SP_RP_DECISIONS = #{SP_RP_DECISIONS}"
end

def increment_start_counts(start_counts, count)
    if start_counts[count].nil?
        start_counts[count] = 1
    else
        start_counts[count] += 1
    end
end

def get_player_starts(table, matchup_number, team_name)
    player_name = table.css("/td/a")[0].content

    position = table.css("/td")[0].content
    if position.match /SP, RP/
        puts "Found SP/RP #{player_name}"
        if SP_RP_MAP[player_name] === true
            puts "Determined to be SP"
            answer = 'y'
        elsif SP_RP_MAP[player_name] === false
            puts "Determine to be RP"
            answer = 'n'
        else
            puts "Are they SP? (y/n)"
            # SP_RP_DECISIONS[:num] += 1
            if player_name.include? "Archie"
                answer = 'n'
            else
                answer = 'y'
            end
            # answer = gets.chomp 
            # answer = 'y'
        end

        if answer == 'y'
            SP_RP_MAP[player_name] = true
            return determine_starts(table, player_name, matchup_number, team_name)
        else
            SP_RP_MAP[player_name] = false
            return 0;
        end
    elsif position.match /SP/
        return determine_starts(table, player_name, matchup_number, team_name)
    end

    return 0;
end

def determine_starts(table, player_name, matchup_number, team_name)
    innings = table.css("/td[@class~=playertableStat]")[0].content
    runs = table.css("/td[@class~=playertableStat]")[2].content.to_i
    innings = innings.to_f
    if innings > 9
        return 2
    elsif innings > 7
        if innings <= runs
            puts "Found #{player_name} going #{innings} IP for #{runs} ER (week #{matchup_number}) on #{team_name}. Marking as 2 starts"
            starts = 2
        else
            if runs < 7
                puts "Found #{player_name} going #{innings} IP for #{runs} ER (week #{matchup_number}) on #{team_name}. Marking as 1 start"
                starts = 1
            else
                puts "Found #{player_name} going #{innings} IP for #{runs} ER (week #{matchup_number}) on #{team_name}. How many starts?"
                # starts = gets.chomp.to_i
                starts = 2
                # starts = 1
            end
        end
        return starts
    elsif innings > 0
        return 1
    end

    return 0
end


parse_starts_per_matchup

