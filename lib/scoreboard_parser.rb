require 'net/http'
require 'date'
require_relative '../lib/espn_fantasy'
require_relative '../lib/parsing_utilities'


class ScoreboardParser

  def initialize(cookie_string, year) 
    @cookie_string = cookie_string
    @year = year
  end

  def parse_scoreboard(league_id, week = nil)
    # Might need to consider following a redirect
    begin
      log_message "Parsing Football Scoreboard"

      response_json = EspnFantasy.get_football_scoreboard_data(@year, league_id, @cookie_string);

      week = response_json['status']['currentMatchupPeriod'] - 1 if week.nil?
      matchups = parse_matchups(response_json, week)
      if verify_scoreboard_data(matchups)
        log_message "Scoreboard data valid [#{Time.now}]"
        save_scores(matchups, week)

        Status.update_service("Football Scoreboard")
      else
        log_message "Scoreboard data Invalid [#{Time.now}]"
        log_message matchups
      end
    rescue Exception => e
      log_message e, "ERROR"
      log_message e.backtrace, "ERROR"
    end
  end

  private 

  def log_message(message, level = "INFO")
    log = Log.new({
      logger: "ScoreboardParser",
      level: level,
      log_message: message,
      time: Time.now
    });
    
    puts message
    log.save!
  end

  def parse_matchups(json, week) 
    matchups = []

    user_index = ParsingUtilities.create_user_index(json['teams'], json['members'])

    schedule = json['schedule'].select {|item| item['matchupPeriodId'] == week }
    schedule.each { |matchup_json|
      matchups.push({
        user1: user_index[matchup_json['away']['teamId']]['user'],
        user2: user_index[matchup_json['home']['teamId']]['user'],
        points1: matchup_json['away']['totalPoints'],
        points2: matchup_json['home']['totalPoints']
      })
    }

    return matchups
  end

  def verify_scoreboard_data(scoreboard_data)
    valid = true

    if(scoreboard_data.size != 6)
      log_message "Invalid matchup length"
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
    season = Season.find_by_sport_and_year('football', @year)

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

end