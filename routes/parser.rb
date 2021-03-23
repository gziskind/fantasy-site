require 'slack-notifier'
require 'redis'

require_relative '../lib/standings_parser'
require_relative '../lib/scoreboard_parser'
require_relative '../lib/draft_parser'
require_relative '../lib/transaction_parser'
require_relative '../lib/player_parser'
require_relative '../lib/common'

class FantasyServer 

  # Views

  # API Calls
  get '/api/parser/token', :auth => :admin do
    {
      token: settings.api_token
    }.to_json
  end

  post '/api/parser/standings/run', :token => true do
    if settings.cookie_string && settings.espn_football_id && settings.espn_baseball_id

      parser = StandingsParser.new(settings.cookie_string, Time.now.year)

      parser.parse_football(settings.espn_football_id) if(Time.now.month >= 9)
      parser.parse_baseball(settings.espn_baseball_id) if(Time.now.month >= 4 && Time.now.month <= 9)

      if(Time.now.month >= 4)
        {
          success:true
        }.to_json
      else
        {
          error: "Not proper time of year for parsing standings"
        }.to_json
      end
    else
      {
        error: "Missing server configuration"
      }.to_json
    end
  end

  post '/api/parser/scoreboard/run', :token => true do
    if settings.cookie_string && settings.espn_football_id

      parser = ScoreboardParser.new(settings.cookie_string, Time.now.year)

      parser.parse_scoreboard(settings.espn_football_id)

      send_football_standings_email()

      {
        success: true
      }.to_json
    else
      {
        error: "Missing server configuration"
      }.to_json
    end
  end

  post '/api/parser/draft/:sport/run', :token => true do
    sport = params[:sport]

    if settings.cookie_string && sport == 'football' && settings.espn_football_id
      parser = DraftParser.new(settings.cookie_string, Time.now.year)

      parser.parse_football_draft(settings.espn_football_id)

      {
        success: true
      }.to_json
    elsif settings.cookie_string && sport == 'baseball' && settings.espn_baseball_id
      parser = DraftParser.new(settings.cookie_string, Time.now.year)

      parser.parse_baseball_draft(settings.espn_baseball_id)

      {
        success: true
      }.to_json
    else
      {
        error: "Missing server configuration"
      }.to_json
    end
  end

  post '/api/parser/transaction/:sport/run', :token => true do
    sport = params[:sport]

    if settings.cookie_string && sport == 'football' && settings.espn_football_id
      parser = TransactionParser.new(settings.cookie_string, Time.now.year)
      retry_attempts = 0

      transactions = []
      while transactions.length == 0 && retry_attempts < settings.transaction_retries
        if retry_attempts > 0
          puts "Transactions empty. Trying again in #{settings.transaction_time} seconds (attempt #{retry_attempts})"
          sleep(settings.transaction_time.to_i)
        end
        transactions = parser.parse_transactions(settings.espn_football_id, 'football')
        retry_attempts += 1
      end

      puts "No transactions found after #{settings.transaction_retries} attempts" if transactions.length == 0

      transaction_string = "*Auction Report for #{Time.now.strftime("%B %d, %Y")}:*\n\n"
      count = 0
      transactions.each {|transaction|
        if transaction[:status] == "EXECUTED"
          count += 1
          if count < 10
            transaction_string += "*%4s.* " % count
          else
            transaction_string += "*%2s.* " % count
          end
        else
          transaction_string += "       "
        end
        transaction_string += parser.slack_format_transaction(transaction)
        transaction_string += "\n"
      }
      slack(settings.slack_football_channel).ping transaction_string if transactions.length > 0

      @transactions = transactions
      emailTemplate = :transactionEmail
      emailTemplate = :noTransactionsEmail if transactions.length == 0
      mail("Football Transaction Report - #{Time.now.strftime("%B %d, %Y")}", erb(emailTemplate, locals: { bgcolor: '#6dbb75'}), settings.football_email_to)

      {
        success: true
      }.to_json
    elsif settings.cookie_string && sport == 'baseball' && settings.espn_baseball_id
      parser = TransactionParser.new(settings.cookie_string, Time.now.year)
      retry_attempts = 0

      transactions = []
      while transactions.length == 0 && retry_attempts < settings.transaction_retries
        if retry_attempts > 0
          puts "Transactions empty. Trying again in #{settings.transaction_time} seconds (attempt #{retry_attempts})"
          sleep(settings.transaction_time.to_i)
        end
        transactions = parser.parse_transactions(settings.espn_baseball_id,'baseball')
        retry_attempts += 1
      end

      puts "No transactions found after #{settings.transaction_retries} attempts" if transactions.length == 0

      transaction_string = "*Auction Report for #{Time.now.strftime("%B %d, %Y")}:*\n\n"
      count = 0
      transactions.each {|transaction|
        if transaction[:status] == "EXECUTED"
          count += 1
          if count < 10
            transaction_string += "*%4s.* " % count
          else
            transaction_string += "*%2s.* " % count
          end
        else
          transaction_string += "       "
        end
        transaction_string += parser.slack_format_transaction(transaction)
        transaction_string += "\n"
      }
      slack(settings.slack_baseball_channel).ping transaction_string if transactions.length > 0

      @transactions = transactions
      mail("Baseball Transaction Report - #{Time.now.strftime("%B %d, %Y")}", erb(:transactionEmail, locals: { bgcolor: '#76a7ea'}), settings.baseball_email_to)

      {
        success: true
      }.to_json
    else
      {
        error: "Missing server configuration"
      }.to_json
    end

  end

  post '/api/parser/players/:sport/run', :token => true do
    sport = params[:sport]

     if settings.cookie_string && sport == 'football' && settings.espn_football_id
      # Do Nothing

      {
        success: true
      }.to_json
    elsif settings.cookie_string && sport == 'baseball' && settings.espn_baseball_id
      parser = PlayerParser.new(settings.cookie_string, Time.now.year)

      players = parser.parse_baseball_players(settings.espn_baseball_id)

      redis = Redis.new({host: settings.redis_host, port: settings.redis_port, password: settings.redis_password})

      players.each {|player|
        unless player[:position] == 'SP' || player[:position] == 'RP'
          user = User.find_by_unique_name(player[:user]);
          opponent = User.find_by_unique_name(player[:opponent])

          name = player[:full_name]
          player_mapping = PlayerMapping.find_by_espn_name(name)
          name = player_mapping.twitter_name if player_mapping

          homerun_slack_ids = []
          steal_slack_ids = []

          if user.slack_id
            homerun_slack_ids.push(user.slack_id) if user.notification_homeruns_team.nil? || user.notification_homeruns_team
            steal_slack_ids.push(user.slack_id) if user.notification_steals_team.nil? || user.notification_steals_team
          end

          if !opponent.nil? && opponent.slack_id
            homerun_slack_ids.push(opponent.slack_id) if opponent.notification_homeruns_opponent.nil? || opponent.notification_homeruns_opponent
            steal_slack_ids.push(opponent.slack_id) if opponent.notification_steals_opponent.nil? || opponent.notification_steals_opponent
          end

          redis.set("player-homerun:#{name}", homerun_slack_ids.join(','), {ex: 86400}) 
          redis.set("player-steal:#{name}", steal_slack_ids.join(','), {ex: 86400}) 
        end
      }

      redis.close

      {
        success: true
      }.to_json
    else
      {
        error: "Missing server configuration"
      }.to_json
    end
  end

  post '/api/parser/teamnames/run', :token => true do
    team_names = TeamName.all

    team_names.each {|team_name|
      rating = get_total_rating team_name

      if !rating.nil?
        team_name.total_rating = rating
        team_name.save!
      end
    }

    {
        success: true
    }.to_json
  end

  def slack(channel)
    if @slack.nil?
      @slack = Slack::Notifier.new(settings.slack_url) do
        defaults username: "Transactions", icon_emoji: ":gavel:", channel: channel
      end
    end

    @slack
  end

  def send_football_standings_email
    zender_results = Common.get_zender_results(Time.now.year, true)

    zender_results.each {|name, result|
      result[:win_percentage]  = (result[:wins] * 2 + result[:points_wins]).to_f / (result[:wins] * 2 + result[:points_wins] + result[:losses] * 2 + result[:points_losses])
    }
    zender_results = zender_results.sort_by {|name, result| [-result[:win_percentage], -result[:points]]}


    mail("Football Standings - #{Time.now.strftime("%B %d, %Y")}", erb(:zenderEmail, locals: {results: zender_results, base_url: settings.base_url}))

  end

  def get_total_rating(team) 
    total_rating = 0
    ratings = Rating.find_all_by_team_name_id(team._id)
    ratings.each {|rating|
      total_rating += rating.rating
    }
    if ratings.length > 0
      total_rating = total_rating / ratings.length.to_f
    else
      total_rating = nil
    end

    total_rating
  end

end

