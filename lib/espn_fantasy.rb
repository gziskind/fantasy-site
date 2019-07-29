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
    return get_data("http://fantasy.espn.com/apis/v3/games/flb/seasons/#{year}/segments/0/leagues/#{league_id}?view=mDraftDetail&view=mTeam&view=kona_draft_recap", cookie_string)
  end

  def self.get_baseball_status(year, league_id, cookie_string)
    return get_data("http://fantasy.espn.com/apis/v3/games/flb/seasons/#{year}/segments/0/leagues/#{league_id}?view=mStatus", cookie_string)
  end

  def self.get_baseball_transaction_data(year, league_id, scoring_period, cookie_string)
    return get_data("http://fantasy.espn.com/apis/v3/games/flb/seasons/#{year}/segments/0/leagues/#{league_id}?scoringPeriodId=#{scoring_period}&view=kona_draft_recap&view=mTeam&view=mTransactions2", cookie_string)
  end

  def self.get_baseball_player_data(year, league_id, cookie_string)
    return get_data("http://fantasy.espn.com/apis/v3/games/flb/seasons/#{year}/segments/0/leagues/#{league_id}?view=kona_draft_recap&view=mTeam&view=mMatchupScore", cookie_string)
  end

  def self.get_team_data(sport)
    return get_data("https://site.web.api.espn.com/apis/site/v2/teams?region=us&lang=en&leagues=#{sport}")[sport]
  end

  def self.get_football_draft_page(year, league_id, cookie_string)
    return get_data("http://games.espn.go.com/ffl/tools/draftrecap?leagueId=#{league_id}&seasonId=#{year}", cookie_string)
  end

  def self.get_baseball_standings_data(year, league_id, cookie_string)
    return get_data("http://fantasy.espn.com/apis/v3/games/flb/seasons/#{year}/segments/0/leagues/#{league_id}?view=mTeam&view=mSettings", cookie_string)
  end

  def self.get_football_standings_page(year, league_id, cookie_string)
    return get_data("http://games.espn.go.com/ffl/standings?leagueId=#{league_id}&seasonId=#{year}", cookie_string)
  end

  def self.get_football_scoreboard_page(year, league_id, cookie_string, matchup = nil)
    path = "http://games.espn.go.com/ffl/scoreboard?leagueId=#{league_id}&seasonId=#{year}"
    unless matchup == nil
      path += "&matchupPeriodId=#{matchup}"
    end

    return get_data(path, cookie_string)
  end

  def self.get_baseball_scoreboard_data(year, league_id, cookie_string)
    return get_data("http://fantasy.espn.com/apis/v3/games/flb/seasons/#{year}/segments/0/leagues/#{league_id}?view=mScoreboard&view=mMatchupScore", cookie_string)
  end

end
