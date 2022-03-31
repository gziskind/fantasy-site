require 'json'
require 'date'
require_relative '../lib/espn_fantasy'
require_relative '../lib/parsing_utilities'

class DraftParser

  def initialize(cookie_string, year) 
    @cookie_string = cookie_string
    @year = year
  end

  def parse_football_draft(league_id)
    begin
      log_message "Parsing #{@year} Football Draft"

      response_json = EspnFantasy.get_football_draft_data(@year, league_id, @cookie_string);

      draft_data = parse_draft_data(response_json, 'football')

      if verify_draft_data(draft_data)
        save_draft_data(draft_data, 'football')
        log_message "Draft data for #{@year} saved"
      else
        log_message "Draft Data Invalid"
        log_message draft_data
      end
    rescue Exception => e
      log_message e, "ERROR"
      log_message e.backtrace, "ERROR"
    end
  end

  def parse_baseball_draft(league_id)
    begin
      log_message "Parsing #{@year} Baseball Draft"

      response_json = EspnFantasy.get_baseball_draft_data(@year, league_id, @cookie_string);

      draft_data = parse_draft_data(response_json, 'baseball')

      if verify_draft_data(draft_data)
        save_draft_data(draft_data, 'baseball')
        log_message "Draft data for #{@year} saved"
      else
        log_message "Draft Data Invalid"
        log_message draft_data
      end
    rescue Exception => e
      log_message e, "ERROR"
      log_message e.backtrace, "ERROR"
    end
  end

  private

   def log_message(message, level = "INFO")
    log = Log.new({
      logger: "DraftParser",
      level: level,
      log_message: message,
      time: Time.now
    });

    puts message
    log.save!
  end

  def parse_draft_data(response_json, sport) 
    draft_data = []

    player_data = EspnFantasy.get_player_data(@year, sport)

    team_index = ParsingUtilities.create_team_index(EspnFantasy.get_team_data('nfl'))
    player_index = ParsingUtilities.create_player_index(player_data, team_index, sport)
    user_index = ParsingUtilities.create_user_index(response_json['teams'], response_json['members'])


    response_json['draftDetail']['picks'].each {|draft_pick|
      player = player_index[draft_pick['playerId']]

      draft_data.push({
        first_name: player[:first_name],
        last_name: player[:last_name],
        position: player[:position],
        pick: draft_pick['overallPickNumber'],
        keeper: draft_pick['keeper'],
        amount: draft_pick['bidAmount'],
        user: user_index[draft_pick['teamId']]['user']
      });
    }
    
    return draft_data
  end

  


  def verify_draft_data(draft_data)
    return !draft_data.nil?
  end

  def save_draft_data(draft_data, sport)
    draft_data.each {|draft_pick_data|
      user = User.find_by_unique_name(/#{draft_pick_data[:user]}/i);
      raise "Could not find user by unique name [#{draft_pick_data[:user]}" if user.nil?

      first_name = draft_pick_data[:first_name]
      last_name = draft_pick_data[:last_name]

      player = Player.find_by_first_name_and_last_name_and_sport(first_name, last_name, sport)
      if(player.nil?)
        player = Player.new({
          first_name: first_name,
          last_name: last_name,
          sport: sport
        })

        player.save!
      end

      pick_conf = {
        position: draft_pick_data[:position],
        pick: draft_pick_data[:pick],
        keeper: draft_pick_data[:keeper],
        year: @year,
        sport: sport,
        user: user,
        player: player
      };

      pick_conf[:cost] = draft_pick_data[:amount] if !draft_pick_data[:amount].nil?

      draft_pick = DraftPick.new(pick_conf)

      draft_pick.save!
    }
  end

end

