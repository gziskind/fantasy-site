require 'net/http'
require 'httparty'
require 'nokogiri'
require 'date'
require_relative '../lib/espn_fantasy'

class ScoreboardParser

  def initialize(user, password, year) 
    @user = user
    @password = password
    @year = year
  end

  def log_message(message, level = "INFO")
    log = Log.new({
      logger: "ScoreboardParser",
      level: level,
      log_message: message,
      time: Time.now
    });

    log.save!
  end

  def parse_scoreboard(league_id, matchup = nil)
    # Might need to consider following a redirect
    begin
      path = "http://games.espn.go.com/ffl/scoreboard?leagueId=#{league_id}&seasonId=#{@year}"
      if matchup == nil
        log_message "Parsing Football Scoreboard"
      else
        log_message "Parsing Football Scoreboard for week #{matchup}"
        path += "&matchupPeriodId=#{matchup}"
      end

      response_body = EspnFantasy.get_page(path, @user, @password);
      html = Nokogiri::HTML(response_body);

      matchups = extract_matchups(html)
      week = extract_week(html)
      if !week.nil? && verify_scoreboard_data(matchups)
        log_message "Scoreboard data valid [#{Time.now}]"
        save_scores(matchups, week)

        Status.update_service("Football Scoreboard")
      else
        log_message "Scoreboard data Invalid [#{Time.now}]"
        log_message matchups
        log_message html if matchups.size == 0
      end
    rescue Exception => e
      log_message e, "ERROR"
    end
  end

  private 

  def extract_week(html)
    week_element = html.css '//em'

    if(week_element.length > 0) 
      match_data = week_element[0].content.match(/Week (\d+)/)

      if(!match_data.nil?)
        return match_data[1].to_i
      else
        match_data = week_element[0].content.match(/Round (\d+)/)
        log_message "Playoff Round #{match_data[1]}" if !match_data.nil?
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
      log_message "Not scoreboard data found"
    end

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