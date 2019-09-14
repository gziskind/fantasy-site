require 'net/http'
require 'httparty'
require 'json'

module EspnFantasy

  def self.get_data(espn_url, cookie_string = nil)
    response = HTTParty.get(espn_url, :headers => {"Cookie" => cookie_string});
    json = JSON.parse(response.body)

    if json['messages'] && !json['messages'].empty? && json['messages'][0].include?("not authorized")
      raise "Login not working"
    end

    return json
  end

  def self.get_baseball_draft_data(year, league_id, cookie_string)
    return get_league_draft_data(year, league_id, cookie_string, 'flb')
  end
  
  def self.get_football_draft_data(year, league_id, cookie_string)
    return get_league_draft_data(year, league_id, cookie_string, 'ffl')
  end

  def get_league_draft_data(year, league_id, cookie_string, league_type)
    return get_data("http://fantasy.espn.com/apis/v3/games/#{league_type}/seasons/#{year}/segments/0/leagues/#{league_id}?view=mDraftDetail&view=mTeam&view=kona_draft_recap", cookie_string)
  end


  def self.get_baseball_status(year, league_id, cookie_string)
    return get_league_status(year, league_id, cookie_string, 'flb')
  end

  def self.get_football_status(year, league_id, cookie_string)
    return get_league_status(year, league_id, cookie_string, 'ffl')
  end

  def self.get_league_status(year, league_id, cookie_string, league_type)
    return get_data("http://fantasy.espn.com/apis/v3/games/#{league_type}/seasons/#{year}/segments/0/leagues/#{league_id}?view=mStatus", cookie_string)
  end


  def self.get_baseball_transaction_data(year, league_id, scoring_period, cookie_string)
    return get_league_transaction_data(year, league_id, scoring_period, cookie_string, 'flb')
  end
  
  def self.get_football_transaction_data(year, league_id, scoring_period, cookie_string)
    return get_league_transaction_data(year, league_id, scoring_period, cookie_string, 'ffl')
  end

  def self.get_league_transaction_data(year, league_id, scoring_period, cookie_string, league_type)
    return get_data("http://fantasy.espn.com/apis/v3/games/#{league_type}/seasons/#{year}/segments/0/leagues/#{league_id}?scoringPeriodId=#{scoring_period}&view=kona_draft_recap&view=mTeam&view=mTransactions2", cookie_string)
  end


  def self.get_baseball_player_data(year, league_id, cookie_string)
    return get_data("http://fantasy.espn.com/apis/v3/games/flb/seasons/#{year}/segments/0/leagues/#{league_id}?view=kona_draft_recap&view=mTeam&view=mMatchupScore", cookie_string)
  end

  def self.get_team_data(sport)
    return get_data("https://site.web.api.espn.com/apis/site/v2/teams?region=us&lang=en&leagues=#{sport}")[sport]
  end


  def self.get_baseball_standings_data(year, league_id, cookie_string)
    return get_league_standings_data(year, league_id, cookie_string, 'flb')
  end

  def self.get_football_standings_data(year, league_id, cookie_string)
    return get_league_standings_data(year, league_id, cookie_string, 'ffl')
  end

  def self.get_league_standings_data(year, league_id, cookie_string, league_type)
    return get_data("http://fantasy.espn.com/apis/v3/games/#{league_type}/seasons/#{year}/segments/0/leagues/#{league_id}?view=mTeam&view=mSettings", cookie_string)
  end


  def self.get_football_scoreboard_data(year, league_id, cookie_string, matchup = nil)
    return get_data("https://fantasy.espn.com/apis/v3/games/ffl/seasons/#{year}/segments/0/leagues/#{league_id}?view=mMatchupScore&view=mRoster&view=mTeam", cookie_string)
  end

  def self.get_baseball_scoreboard_data(year, league_id, cookie_string)
    return get_data("http://fantasy.espn.com/apis/v3/games/flb/seasons/#{year}/segments/0/leagues/#{league_id}?view=mScoreboard&view=mMatchupScore", cookie_string)
  end

end
