require 'json'
require 'date'
require_relative '../lib/espn_fantasy'
require_relative '../lib/parsing_utilities'

class TransactionParser


  def initialize(cookie_string, year) 
    @cookie_string = cookie_string
    @year = year
  end

  def parse_transactions(league_id, sport)
    if sport == 'baseball'
      league_type = 'flb'
    else
      league_type = 'ffl'
    end

  	current_scoring_period, last_waiver_time = get_current_scoring_period_and_waiver_time(league_id, league_type);

  	response_json = EspnFantasy.get_league_transaction_data(@year, league_id, current_scoring_period, @cookie_string, league_type)

  	transactions = parse_transaction_data(response_json, Time.at(last_waiver_time/1000), sport)

    transactions.sort_by! {|transaction| [-transaction[:bid], transaction[:suborder]]}

    return transactions
  end

  def slack_format_transaction(transaction) 
    added_player = transaction[:items].find {|player| player[:type] == "ADD" }
    dropped_player = transaction[:items].find {|player| player[:type] == "DROP" }

    str = "*$#{transaction[:bid]}* bid by *#{transaction[:user]}* on *#{added_player[:player][:first_name]} #{added_player[:player][:last_name]} #{added_player[:player][:team][:abbrev]}, #{added_player[:player][:position]}*."
    if(transaction[:status] == "EXECUTED")
      str += " Added."
      unless dropped_player.nil?
        str += " Dropped *#{dropped_player[:player][:first_name]} #{dropped_player[:player][:last_name]} #{dropped_player[:player][:team][:abbrev]}, #{dropped_player[:player][:position]}*"
      end
    elsif(transaction[:status] == "FAILED_PLAYERALREADYDROPPED")
      str += " Unsuccessful. Reason: A player involved has already been dropped"
    elsif(transaction[:status] == "FAILED_INVALIDPLAYERSOURCE")
      str += " Unsuccessful. Reason: Player has already been added to another team."
    elsif(transaction[:status] == "FAILED_ROSTERLIMIT")
      str += " Unsuccessful. Reason: Maximum roster size would be exceeded."
    elsif(transaction[:status] == "FAILED_ROSTERLOCK")
      str += " Unsuccessful. Reason: Unable to process, rosters are locked."
    end

    str
  end
 
  def get_current_scoring_period_and_waiver_time(league_id, league_type)
 	  status = EspnFantasy.get_league_status(@year, league_id, @cookie_string, league_type)

 	  return status['status']['latestScoringPeriod'], status['status']['waiverLastExecutionDate']
  end

  def parse_transaction_data(response_json, last_waiver_time, sport)
    transaction_data = []

    if sport == 'baseball'
      league = 'mlb'
    else
      league = 'nfl'
    end

    player_data = EspnFantasy.get_player_data(@year)

    team_index = ParsingUtilities.create_team_index(EspnFantasy.get_team_data(league))
    player_index = ParsingUtilities.create_player_index(player_data, team_index, sport)
    user_index = ParsingUtilities.create_user_index(response_json['teams'], response_json['members'])

    response_json['transactions'].each {|transaction|
      items = []
      if transaction.key?("items") 
        transaction['items'].each {|item|
          items.push({
            player: player_index[item['playerId']],
            type: item['type'],
          })
        }
      end

      transaction_time = Time.at(transaction['processDate'].to_i/1000)

      transaction_data.push({
        bid: transaction['bidAmount'],
        execution_type: transaction['executionType'],
        status: transaction['status'],
        type: transaction['type'],
        user: user_index[transaction['teamId']]['user'],
        team_name: user_index[transaction['teamId']]['team_name'],
        suborder: transaction['subOrder'],
        items: items
      }) if transaction['type'] == 'WAIVER' && transaction['executionType'] == 'PROCESS' && transaction_time.between?(last_waiver_time - 600, last_waiver_time + 600)
    }

    return transaction_data
  end
end


