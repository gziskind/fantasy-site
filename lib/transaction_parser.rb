require 'json'
require 'date'
require_relative '../lib/espn_fantasy'
require_relative '../lib/parsing_utilities'

class TransactionParser


  def initialize(cookie_string, year) 
    @cookie_string = cookie_string
    @year = year
  end

  def parse_baseball_transactions(league_id)
  	current_scoring_period = get_current_scoring_period(league_id);

  	response_json = EspnFantasy.get_baseball_transaction_data(@year, league_id, current_scoring_period, @cookie_string)

  	transactions = parse_transaction_data(response_json)

    transactions.sort_by! {|transaction| [-transaction[:bid], transaction[:suborder]]}

    return transactions
  end

  def slack_format_transaction(transaction) 
    added_player = transaction[:items].find {|player| player[:type] == "ADD" }
    dropped_player = transaction[:items].find {|player| player[:type] == "DROP" }

    # puts transaction[:status]
    # puts transaction[:type]
    # puts transaction[:execution_type]

    str = "*$#{transaction[:bid]}* bid by *#{transaction[:user]}* on *#{added_player[:player][:first_name]} #{added_player[:player][:last_name]}, #{added_player[:player][:position]}*."
    if(transaction[:status] == "EXECUTED")
      str += " Added."
      unless dropped_player.nil?
        str += " Dropped *#{dropped_player[:player][:first_name]} #{dropped_player[:player][:last_name]}, #{dropped_player[:player][:position]}*"
      end
    elsif(transaction[:status] == "FAILED_PLAYERALREADYDROPPED")
      str += " Unsuccessful. Reason: A player involved has already been dropped"
    elsif(transaction[:status] == "FAILED_INVALIDPLAYERSOURCE")
      str += " Unsuccessful. Reason: Player has already been added to another team."
    elsif(transaction[:status] == "FAILED_ROSTERLIMIT")
      str += " Unsuccessful. Reason: Maximum roster size would be exceeded."
    end

    str
  end
 
  def get_current_scoring_period(league_id)
 	  status = EspnFantasy.get_baseball_status(@year, league_id, @cookie_string)

 	  return status['status']['latestScoringPeriod']
  end

  def parse_transaction_data(response_json)
    transaction_data = []

    player_index = ParsingUtilities.create_player_index(response_json["players"])
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

      transaction_data.push({
        bid: transaction['bidAmount'],
        execution_type: transaction['executionType'],
        status: transaction['status'],
        type: transaction['type'],
        user: user_index[transaction['teamId']],
        suborder: transaction['subOrder'],
        items: items
      }) if transaction['type'] == 'WAIVER' && transaction['executionType'] == 'PROCESS'
    }

    return transaction_data
  end
end


