require_relative '../lib/standings_parser'
require_relative '../lib/scoreboard_parser'

class FantasyServer 

  # Views

  # API Calls
  post '/api/parser/standings/run', :token => true do
    if settings.cookie_string && settings.espn_football_id && settings.espn_baseball_id

      parser = StandingsParser.new(settings.cookie_string, Time.now.year)

      if(Time.now.month >= 9 && Time.now.month <= 12)
        parser.parse_football(settings.espn_football_id)

        {
          success:true
        }.to_json
      elsif(Time.now.month >= 4 && Time.now.month <= 9)
        parser.parse_baseball(settings.espn_baseball_id) 
        parser.parse_roto(settings.espn_baseball_id)

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
end

