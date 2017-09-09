require_relative '../lib/espn_fantasy'

describe EspnFantasy do
  describe "login function" do
    it "logs into espn and returns valid cookies" do
      response = EspnFantasy.get_page('http://games.espn.com/flb/clubhouse?leagueId=33843&teamId=8&seasonId=2017','gziskind','44ndIqd3zTlOQNOoMclk')
      puts response
    end
  end
end

# 9CIzgWFEKvjEplraivJzXz1POIVEOnC7ATt4PR+kCK+CDaUR1PDDHlYOD+TG9bsWQd1oJZnGafiMnCEUH5klsHDcqQ==