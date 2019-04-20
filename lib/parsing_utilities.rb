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

  def self.create_player_index(players)
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

  def self.create_user_index(teams, members)
    user_index = {}

    member_index = create_member_index(members)

    teams.each {|team|
      user_index[team['id']] = member_index[team['primaryOwner']]
    }

    return user_index
  end

  def self.create_member_index(members)
    member_index = {}

    members.each {|member|
      member_index[member['id']] = "#{member['firstName']} #{member['lastName']}"
    }

    return member_index
  end
end