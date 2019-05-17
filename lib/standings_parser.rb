require 'net/http'
require 'date'
require_relative '../lib/espn_fantasy'
require_relative '../lib/parsing_utilities'


class StandingsParser

  def initialize(cookie_string, year) 
    @cookie_string = cookie_string
    @year = year
  end

  def parse_baseball(league_id)
    begin
      log_message "Parsing #{@year} Baseball Standings"

      standings_data = EspnFantasy.get_baseball_standings_data(@year, league_id, @cookie_string);

      league_name = standings_data['settings']['name'];
      team_info = parse_team_info(standings_data['teams'], standings_data['members'])

      if verify_team_baseball_info(team_info)
        log_message "Team info valid [#{Time.now}]"
        save_standings_baseball league_name, team_info
        save_team_names_baseball team_info

        Status.update_service("Baseball Standings")
      else
        log_message "Team info Invalid [#{Time.now}]"
        log_message team_info
      end
    rescue Exception => e
      log_message e, "ERROR"
      log_message e.backtrace, "ERROR"
    end
    end
  end

  def parse_football(league_id)
    begin
      log_message "Parsing #{@year} Football Standings"

      response_body = EspnFantasy.get_football_standings_page(@year, league_id, @cookie_string);

      html = Nokogiri::HTML(response_body);
      league_name = extract_league_name html;
      team_info = extract_team_info html, true

      if verify_team_football_info(team_info)
        log_message "Team info valid [#{Time.now}]"
        save_standings_football league_name, team_info
        save_team_names_football team_info

        Status.update_service("Football Standings")
      else
        log_message "Team info Invalid [#{Time.now}]"
        log_message team_info
      end
    rescue Exception => e
      log_message e, "ERROR"
    end
  end

  def parse_roto(league_id)
    begin
      log_message "Parsing #{@year} Baseball Roto Stats"

      response_body = EspnFantasy.get_baseball_standings_page(@year, league_id, @cookie_string);
      html = Nokogiri::HTML(response_body);

      stats = parse_roto_data(html)

      if verify_roto_stats(stats)
        log_message "Roto stats valid [#{Time.now}]"
        calculate_points(stats) 

        Status.update_service("Roto Standings")
      else
        log_message "Roto stats invalid [#{Time.now}]"
        log_message stats.to_s
      end
    rescue Exception => e
      log_message e, "ERROR"
    end
  end

  private

  def parse_team_info(teams_data, members_data) 
    teams = []

    user_index = ParsingUtilities.create_user_index(teams_data, members_data)

    teams_data.each {|team_data|
      teams.push({
        team_name: "#{team_data['location']} #{team_data['nickname']}",
        owner: user_index[team_data['id']],
        wins: team_data['record']['overall']['wins'],
        losses: team_data['record']['overall']['losses'],
        ties: team_data['record']['overall']['ties'],
        place: team_data['playoffSeed']
      })
    }

    return teams
  end

  def log_message(message, level = "INFO")
    log = Log.new({
      logger: "StandingsParser",
      level: level,
      log_message: message,
      time: Time.now
    });

    puts message
    log.save!
  end

  def extract_team_football_info(html)
    extract_team_info html, true
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
    info.each_with_index {|team|
      user = User.find_by_unique_name(team[:owner]);

      result_data = {
        place: team[:place],
        team_name: team[:team_name],
        wins: team[:wins],
        losses: team[:losses],
        ties: team[:ties],
        user: user
      }
      result_data[:points] = team[:points] if !team[:points].nil?
      results.push(result_data);
    }

    season = Season.find_by_sport_and_year sport, @year
    if !season.nil?
      log_message "Updating Existing Season"
      season.results.each_with_index {|result, index|
        result.place = results[index][:place]
        result.team_name = results[index][:team_name]
        result.wins = results[index][:wins]
        result.losses = results[index][:losses]
        result.ties = results[index][:ties]
        result.user = results[index][:user]

        result.points = results[index][:points] if !results[index][:points].nil?
      }

      season.year = @year
      season.sport = sport
      season.league_name = league_name
    else
      log_message "Creating new season"
      new_results = []
      results.each{|result_data|
        new_results.push(result_class.new(result_data))
      }

      season_data = {
        year: @year,
        sport: sport,
        league_name: league_name,
        results: new_results
      }

      season = Season.new(season_data);   
    end

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

        if @year != Time.now.year
          team_name.year = @year;
        end

        log_message "Adding team name [#{team[:team_name]}]"

        team_name.save!
      elsif owner.nil?
        log_message "Could not find owner [#{team[:owner]}]"
      else
        log_message "Team name [#{team[:team_name]}] already in database"
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

  def verify_roto_stats(stats)
    valid = true

    stats.each {|stat_line| 
      fields = [:name, :total_points, 
        :runs, :runs_points, :homeruns, :homeruns_points, :rbi, :rbi_points, :sb, :sb_points, :average, :average_points, :ops, :ops_points,
        :quality_starts, :quality_starts_points, :wins, :wins_points, :saves, :saves_points, :era, :era_points, :whip, :whip_points, :k_per_9, :k_per_9_points
      ]
      fields.each{ |field|
        if stat_line[field].nil?
          valid = false
        end
      }
    }

    return valid
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

end