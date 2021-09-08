require 'json'
require 'date'
require_relative '../lib/espn_fantasy'
require_relative '../lib/parsing_utilities'

class PlayerParser


  def initialize(cookie_string, year) 
    @cookie_string = cookie_string
    @year = year
  end

  def parse_baseball_players(league_id)
    response_json = EspnFantasy.get_baseball_player_data(@year, league_id, @cookie_string)

    players = parse_player_data(response_json)

    return players
  end

  def parse_player_data(response_json)
    player_data = []

    user_index = ParsingUtilities.create_user_index(response_json['teams'], response_json['members'])
    opponent_index = ParsingUtilities.create_opponent_index(response_json['schedule']);

    response_json['teams'].each {|team|
      user = user_index[team['id']]['user']
      opponent_team = opponent_index[team['id']][response_json['status']['currentMatchupPeriod']]
      unless opponent_team.nil?
        opponent = user_index[opponent_team]['user']

        team['roster']['entries'].each {|entry|
          player = entry['playerPoolEntry']['player']

          player_data.push({
            full_name: player['fullName'],
            first_name: player['firstName'],
            last_name: player['lastName'],
            position: ParsingUtilities.baseball_positions_map[player['defaultPositionId']],
            user: user,
            opponent: opponent
          })
        }
      end
    }

    return player_data
  end
end

