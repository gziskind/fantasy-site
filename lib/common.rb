module Common

	def self.get_zender_results(year, is_logged_in)
    season = Season.find_by_sport_and_year('football',year)

    zender_results = {}
    season.results.each{|result|
      zender_results[result.user.name] = {
        wins: result.wins,
        losses: result.losses,
        ties: result.ties,
        points: result.points,
        points_wins: 0,
        points_losses: 0,
        results:[]
      }

      zender_results[result.user.name][:team_name] = result.team_name if is_logged_in
    }

    season.week_results.each {|week_result|
      team_results = []
      week_result.matchups.each{|matchup|
        win = matchup.team_results[0][:points] > matchup.team_results[1][:points]

        team_results.push({
          result: matchup.team_results[0],
          win: win
        })
        team_results.push({
          result: matchup.team_results[1],
          win: !win
        })
      }

      team_results.sort_by! {|team_result| team_result[:result][:points]}
      team_results.reverse!

      team_results.each_with_index {|team_result,index|
        zender_results[team_result[:result].user.name][:results].push({
          place: index + 1,
          points: team_result[:result][:points],
          win: team_result[:win]
        })

        if(index < 6)
          zender_results[team_result[:result].user.name][:points_wins] += 1
        else
          zender_results[team_result[:result].user.name][:points_losses] += 1
        end
      }
    }

    return zender_results
  end
end