require 'slack-notifier'
require 'redis'

require_relative '../lib/standings_parser'
require_relative '../lib/scoreboard_parser'
require_relative '../lib/draft_parser'
require_relative '../lib/transaction_parser'
require_relative '../lib/player_parser'

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

      parser.parse_football_transactions(settings.espn_football_id)

      {
        success: true
      }.to_json
    elsif settings.cookie_string && sport == 'baseball' && settings.espn_baseball_id
      parser = TransactionParser.new(settings.cookie_string, Time.now.year)

      transactions = parser.parse_baseball_transactions(settings.espn_baseball_id)

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
      slack.ping transaction_string

      @transactions = transactions
      mail("Baseball Transaction Report - #{Time.now.strftime("%B %d, %Y")}", erb(:transactionEmail))

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
        user = User.find_by_unique_name(player[:user]);

        if user.slack_username
          puts user.slack_username
          redis.set("player:#{player[:full_name]}", user.slack_username,{ex: 86400})
        end
        puts player
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

  def slack
    if @slack.nil?
      channel = settings.slack_channel
      @slack = Slack::Notifier.new(settings.slack_url) do
        defaults username: "Transactions", icon_emoji: ":gavel:", channel: channel
      end
    end

    @slack
  end

end

