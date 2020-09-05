module ParsingUtilities

  BASEBALL_POSITIONS_MAP = {
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

  FOOTBALL_POSITIONS_MAP = {
    1 => "QB",
    2 => "RB",
    3 => "WR",
    4 => "TE"
  }

  def self.baseball_positions_map
    BASEBALL_POSITIONS_MAP
  end

  def self.FOOTBALL_POSITIONS_MAP
    FOOTBALL_POSITIONS_MAP
  end

  # Create a map of matchupPeriodId to opponent_id of team for each team_id
  # {
  #   "<team-id>":{
  #     "<matchup-id>":"<opponent-team-id>",
  #     ...
  #   },
  #   ...
  # }
  def self.create_opponent_index(schedule) 
    opponent_index = {}
    schedule.each {|matchup|
      home_id = matchup['home']['teamId']
      opponent_index[home_id] = {} if opponent_index[home_id].nil?

      if matchup['away']
        away_id = matchup['away']['teamId']
        opponent_index[home_id][matchup['matchupPeriodId']] = away_id
        opponent_index[away_id] = {} if opponent_index[away_id].nil?
        opponent_index[away_id][matchup['matchupPeriodId']] = home_id
      end
    }

    return opponent_index
  end

  # Create map of player id to player info
  def self.create_player_index(players, team_index, sport)
    player_index = {}
    if sport == 'baseball'
      positions_map = BASEBALL_POSITIONS_MAP
    else
      positions_map = FOOTBALL_POSITIONS_MAP
    end

    players.each {|player|
      player_index[player['id']] = {
        first_name: player['firstName'],
        last_name: player['lastName'],
        position: positions_map[player['defaultPositionId']],
        team: team_index[player['proTeamId'].to_s]
      }
    }

    return player_index
  end

  # Creates map of user team id to member name
  def self.create_user_index(teams, members)
    user_index = {}

    member_index = create_member_index(members)

    teams.each {|team|
      user_index[team['id']] = {
        'user' => member_index[team['primaryOwner']],
        'team_name' => "#{team['location']} #{team['nickname']}"
      }
    }

    return user_index
  end

  # Creates map of member id to member name
  def self.create_member_index(members)
    member_index = {}

    members.each {|member|
      member_index[member['id']] = "#{member['firstName']} #{member['lastName']}"
    }

    return member_index
  end

  # Creates map of mlb team id to mlb team info
  def self.create_team_index(team_data)
    team_index = {}

    teams = team_data.each {|division|
      division['teams'].each {|team|
        team_index[team['id']] = {
          display_name: team['displayName'],
          abbrev: team['abbreviation'],
          short_display_name: team['shortDisplayName']
        }
      }
    }

    team_index["0"] = {
      display_name: "Free Agent",
      abbrev: "FA",
      short_display_name: "Free Agent"
    }

    return team_index
  end
end