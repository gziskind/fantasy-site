module ParsingUtilities

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

  def self.positions_map
    POSITIONS_MAP
  end

  # Create map of player id to player info
  def self.create_player_index(players, team_index)
    player_index = {}

    players.each {|player|
      player_index[player['id']] = {
        first_name: player['player']['firstName'],
        last_name: player['player']['lastName'],
        position: POSITIONS_MAP[player['player']['defaultPositionId']],
        team: team_index[player['player']['proTeamId'].to_s]
      }
    }

    return player_index
  end

  # Creates map of user team id to member name
  def self.create_user_index(teams, members)
    user_index = {}

    member_index = create_member_index(members)

    teams.each {|team|
      user_index[team['id']] = member_index[team['primaryOwner']]
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