class FantasyServer 
	# Views
	get '/:sport/champions' do
		@header_index = params[:sport]
		@sport = params[:sport]

		@champions = []

		seasons = Season.find_all_by_sport(@sport);
		@seasons = seasons.map {|season|
			winner_index = season.results.find_index {|result|
				result.place == 1
			}

			winner = season.results[winner_index]

			runner_up_index = season.results.find_index {|result|
				result.place == 2
			}
			runner_up = season.results[runner_up_index]

			@champions.push({
				year: season.year,
				team_name: winner.team_name,
				winner: winner.user.name,
				record: winner.record,
				result: season.championship_score,
				runner_up: runner_up.user.name
			}) if !season.championship_score.nil?

		}

		@champions.sort_by! {|champion| champion[:year]}
		@champions.reverse!

		erb :champions
	end
end