require 'net/http'
require 'httparty'
require 'nokogiri'
require 'date'
require_relative '../lib/espn_fantasy'

class StandingsParser

  ORDER =["C","1B","2B","SS","3B","OF","DH","SP","RP"]

  def initialize(user, password) 
    @user = user
    @password = password
  end

  def parse_baseball(league_id, year)
    puts "Parsing #{year} Baseball Standings"

    baseball_url = "http://games.espn.go.com/flb/standings?leagueId=#{league_id}&seasonId=#{year}"
    response_body = EspnFantasy.get_page(baseball_url, @user, @password);

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

  def parse_football(league_id, year)
    puts "Parsing #{year} Football Standings"

    football_url = "http://games.espn.go.com/ffl/standings?leagueId=#{league_id}&seasonId=#{year}"
    response_body = EspnFantasy.get_page(football_url, @user, @password);

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

  def parse_roto(league_id, year)
    puts "Parsing #{year} Baseball Roto Stats"

    baseball_url = "http://games.espn.go.com/flb/standings?leagueId=#{league_id}&seasonId=#{year}"

    response_body = EspnFantasy.get_page(baseball_url, @user, @password);
    html = Nokogiri::HTML(response_body);

    stats = parse_roto_data(html)

    if verify_roto_stats(stats)
      puts "Roto stats valid [#{Time.now}]"
      calculate_points(stats) 
    else
      puts "Roto stats invalid [#{Time.now}]"
      puts stats.to_s
    end
  end

  private

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
      results.push(result_data);
    }

    season = Season.find_by_sport_and_year sport, YEAR
    if !season.nil?
      puts "Updating Existing Season"
      season.results.each_with_index {|result, index|
        result.place = results[index][:place]
        result.team_name = results[index][:team_name]
        result.wins = results[index][:wins]
        result.losses = results[index][:losses]
        result.ties = results[index][:ties]
        result.user = results[index][:user]

        result.points = results[index][:points] if !results[index][:points].nil?
      }

      season.year = YEAR
      season.sport = sport
      season.league_name = league_name
    else
      puts "Creating new season"
      new_results = []
      results.each{|result_data|
        new_results.push(result_class.new(result_data))
      }

      season_data = {
        year: YEAR,
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