class FantasyServer 

	# Views
	get '/:sport/results' do
		@sport = params[:sport];
		@header_index = @sport;

		seasons = Season.find_all_by_sport(@sport);
		@seasons = seasons.map {|season|
			season.year
		}

		@seasons.sort!.reverse!

		erb :results
	end


	# API Calls
	get '/api/:sport/results' do
		seasons = Season.find_all_by_sport(params[:sport]);
		results = seasons.map {|season|
			{
				year: season.year,
				sport: season.sport,
				league_name: season.league_name,
				championship_score: season.championship_score,
				results: season.results.map {|result|
					return_data = {
						name: result.team_name,
						owner: result.user.name,
						wins: result.wins,
						losses: result.losses,
						ties: result.ties,
						place: result.place
					}

					return_data[:points] = result.points if params[:sport] == 'football'

					return_data
				}
			}
		}

		results.sort_by! {|result| result[:year]}
		results.reverse!

		results.to_json
	end

	get '/api/:sport/results/:year' do
		season = Season.find_by_sport_and_year(params[:sport], params[:year].to_i);

		results = season.results.map {|result|
			return_data = {
				name: result.team_name,
				owner: result.user.name,
				wins: result.wins,
				losses: result.losses,
				ties: result.ties,
				place: result.place
			}

			return_data[:points] = result.points if params[:sport] == 'football'

			return_data
		}

		results.sort_by! {|result| result[:place]}

		results.to_json
	end
end