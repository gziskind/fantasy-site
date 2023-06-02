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
      parser.parse_baseball(settings.espn_baseball_id) if(Time.now.month >= 3 && Time.now.month <= 9)

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
    if sport == 'football'
      league_id = settings.espn_football_id
      slack_channel = settings.slack_football_channel
      email_to = settings.football_email_to
      email_color = '#6dbb75'
    elsif sport == 'baseball'
      league_id = settings.espn_baseball_id
      slack_channel = settings.slack_baseball_channel
      email_to = settings.baseball_email_to
      email_color = '#76a7ea'
    end


    if settings.cookie_string && league_id
      parser = TransactionParser.new(settings.cookie_string, Time.now.year)
      retry_attempts = 0

      transactions = []
      while transactions.length == 0 && retry_attempts < settings.transaction_retries
        if retry_attempts > 0
          puts "Transactions empty. Trying again in #{settings.transaction_time} seconds (attempt #{retry_attempts})"
          sleep(settings.transaction_time.to_i)
        end
        transactions = parser.parse_transactions(league_id, sport)
        retry_attempts += 1
      end

      save_transactions(transactions, sport)

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
      slack(slack_channel).ping transaction_string if transactions.length > 0

      @transactions = transactions
      emailTemplate = :transactionEmail
      emailTemplate = :noTransactionsEmail if transactions.length == 0
      mail("#{sport.capitalize} Transaction Report - #{Time.now.strftime("%B %d, %Y")}", erb(emailTemplate, locals: { bgcolor: email_color}), email_to)

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
          user = User.find_by_unique_name(/#{player[:user]}/i);
          opponent = User.find_by_unique_name(/#{player[:opponent]}/i)

          name = player[:full_name]
          player_mapping = PlayerMapping.find_by_espn_name(name)
          name = player_mapping.twitter_name if player_mapping

          homerun_ids = []
          steal_ids = []

          if user.slack_id || user.telegram_id
            id = user.slack_id
            id = user.telegram_id unless user.telegram_id.nil?

            homerun_ids.push(id) if user.notification_homeruns_team.nil? || user.notification_homeruns_team
            steal_ids.push(id) if user.notification_steals_team.nil? || user.notification_steals_team
          end

          if(!opponent.nil? && (opponent.slack_id || opponent.telegram_id))
            id = opponent.slack_id
            id = opponent.telegram_id unless opponent.telegram_id.nil?

            homerun_ids.push(id) if opponent.notification_homeruns_opponent.nil? || opponent.notification_homeruns_opponent
            steal_ids.push(id) if opponent.notification_steals_opponent.nil? || opponent.notification_steals_opponent
          end

          redis.set("player-homerun:#{name}", homerun_ids.join(','), {ex: 86400}) 
          redis.set("player-steal:#{name}", steal_ids.join(','), {ex: 86400}) 
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


    mail("Football Standings - #{Time.now.strftime("%B %d, %Y")}", erb(:zenderEmail, locals: {results: zender_results, base_url: settings.base_url}), settings.football_email_to)

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

  def save_transactions(transactions, sport) 
    transactions.each {|transaction|
      if transaction[:status] == "EXECUTED"
        user = User.find_by_unique_name(/#{transaction[:user]}/i)
        transaction[:items].each { |add_or_drop| 
          player = Player.find_by_first_name_and_last_name_and_sport(add_or_drop[:player][:first_name], add_or_drop[:player][:last_name], sport)

          if player.nil?
            player = Player.new({
              first_name: add_or_drop[:player][:first_name],
              last_name: add_or_drop[:player][:last_name],
              sport: sport
            })

            player.save!
          end

          transactionNew = Transaction.find_by_player_id_and_date(player._id, Date.today)
          if transactionNew.nil?
            transactionNew = Transaction.new({
              type: add_or_drop[:type],
              bid: add_or_drop[:type] == 'ADD' ? transaction[:bid] : nil,
              date: Date.today,
              user: user,
              player:player
            })

            transactionNew.save!
          end

        }
      end
    }
  end

end

