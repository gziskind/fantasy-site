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

    response_json['players'].each {|player|
      if(player['onTeamId'] != 0) 
        user = user_index[player['onTeamId']]

        player_data.push({
          full_name: player['player']['fullName'],
          first_name: player['player']['firstName'],
          last_name: player['player']['lastName'],
          position: ParsingUtilities.positions_map[player['player']['defaultPositionId']],
          user: user
        }) 
      end
    }

    return player_data
  end
end


