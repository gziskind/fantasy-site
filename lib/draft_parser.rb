require 'json'
require 'net/http'
require 'httparty'
require 'date'
require_relative '../lib/espn_fantasy'

class DraftParser
  POSITIONS_MAP = {
    1 => "SP",
    2 => "C",
    3 => "1B",
    4 => "2B",
    5 => "3B",
    6 => "SS",
    7 => "OF",
    8 => "OF",
    9 => "OF",
    10 => "DH",
    11 => "RP"
  }

  def initialize(cookie_string, year) 
    @cookie_string = cookie_string
    @year = year
  end

  def get_baseball_draft_data_from_file(file)
    name_map = JSON.parse(File.read("user_map.json"))
    pick_num = 1
    draft_data =[]

    File.open(file).each {|line|
      match_data = line.match(/(\w+)\s-\s([A-Za-z. \-']+)[ ]([(]K\d?[)])?[ ]?(\w+)/)

      if(!match_data.nil?)
        team = match_data[1]
        name = match_data[2]
        keeper = !match_data[3].nil? 
        position = match_data[4].upcase

        if POSITIONS_MAP.values.include? position

          draft_data.push({
            name: name.strip,
            position: position,
            pick: pick_num,
            user: name_map[team],
            keeper: keeper
          })
        else
          puts "Position invalid [#{name}] [#{position}]"
        end

        pick_num += 1
      end
    }

    return draft_data
  end

  def parse_football_draft(league_id)
    begin
      log_message "Parsing #{@year} Football Draft"

      response_body = EspnFantasy.get_football_draft_page(@year, league_id, @cookie_string);

      draft_data = parse_draft_data(response_body)

      if verify_draft_data(draft_data)
        save_draft_data(draft_data, 'football')
        log_message "Draft data for #{@year} saved"
      else
        log_message "Draft Data Invalid"
        log_message draft_data
      end
    rescue Exception => e
      log_message e, "ERROR"
    end
  end

  def parse_baseball_draft(league_id)
    begin
      log_message "Parsing #{@year} Baseball Draft"

      response_json = EspnFantasy.get_baseball_draft_data(@year, league_id, @cookie_string);

      draft_data = parse_draft_data(response_json)

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

  def parse_draft_data(response_json) 
    draft_data = []

    player_index = create_player_index(response_json["players"])
    user_index = create_user_index(response_json['teams'], response_json['members'])

    response_json['draftDetail']['picks'].each {|draft_pick|
      player = player_index[draft_pick['playerId']]

      draft_data.push({
        first_name: player[:first_name],
        last_name: player[:last_name],
        position: player[:position],
        pick: draft_pick['overallPickNumber'],
        keeper: draft_pick['keeper'],
        amount: draft_pick['bidAmount'],
        user: user_index[draft_pick['teamId']]
      });
    }
    
    return draft_data
  end

  def create_player_index(players)
    player_index = {}

    players.each {|player|
      player_index[player['id']] = {
        first_name: player['player']['firstName'],
        last_name: player['player']['lastName'],
        position: POSITIONS_MAP[player['player']['defaultPositionId']]
      }
    }

    return player_index
  end

  def create_user_index(teams, members)
    user_index = {}

    member_index = create_member_index(members)

    teams.each {|team|
      user_index[team['id']] = member_index[team['primaryOwner']]
    }

    return user_index
  end

  def create_member_index(members)
    member_index = {}

    members.each {|member|
      member_index[member['id']] = "#{member['firstName']} #{member['lastName']}"
    }

    return member_index
  end


  def verify_draft_data(draft_data)
    return !draft_data.nil?
  end

  def save_draft_data(draft_data, sport)
    draft_data.each {|draft_pick_data|
      user = User.find_by_unique_name(draft_pick_data[:user]);
      raise "Could not find user by unique name" if user.nil?

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

