require 'net/http'
require 'httparty'
require 'nokogiri'

module EspnFantasy

  def self.get_page(espn_url, cookie_string)
    response = HTTParty.get(espn_url, :headers => {"Cookie" => cookie_string});

    return response.body
  end

  def self.get_baseball_draft_page(year, league_id, cookie_string)
    return get_page("http://games.espn.go.com/flb/tools/draftrecap?leagueId=#{league_id}&seasonId=#{year}", cookie_string)
  end

  def self.get_football_draft_page(year, league_id, cookie_string)
    return get_page("http://games.espn.go.com/ffl/tools/draftrecap?leagueId=#{league_id}&seasonId=#{year}", cookie_string)
  end

  def self.get_baseball_standings_page(year, league_id, cookie_string)
    return get_page("http://games.espn.go.com/flb/standings?leagueId=#{league_id}&seasonId=#{year}",cookie_string)
  end

  def self.get_football_standings_page(year, league_id, cookie_string)
    return get_page("http://games.espn.go.com/ffl/standings?leagueId=#{league_id}&seasonId=#{year}", cookie_string)
  end

  def self.get_football_scoreboard_page(year, league_id, cookie_string, matchup = nil)
    path = "http://games.espn.go.com/ffl/scoreboard?leagueId=#{league_id}&seasonId=#{year}"
    unless matchup == nil
      path += "&matchupPeriodId=#{matchup}"
    end

    return get_page(path, cookie_string)
  end

  def self.get_baseball_matchup_stats_page(year, league_id, cookie_string, matchup)
    return get_page("http://games.espn.go.com/flb/scoreboard?leagueId=#{league_id}&seasonId=#{year}&matchupPeriodId=#{matchup}", cookie_string)
  end

end

