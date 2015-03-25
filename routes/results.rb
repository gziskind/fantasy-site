class FantasyServer 

	# Views
	get '/:sport/results' do
		event "#{params[:sport].capitalize}Results"
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
			season_result = {
				year: season.year,
				sport: season.sport,
				league_name: season.league_name,
				championship_score: season.championship_score,
				results: season.results.map {|result|
					return_data = {
						owner: result.user.name,
						wins: result.wins,
						losses: result.losses,
						ties: result.ties,
						place: result.place
					}

					return_data[:name] = result.team_name if !@user.nil?

					return_data[:points] = result.points if params[:sport] == 'football'

					return_data
				}
			}

			season_result[:league_name] = season.league_name if !@user.nil?

			season_result
		}

		results.sort_by! {|result| result[:year]}
		results.reverse!

		results.to_json
	end

	get '/api/:sport/results/:year' do
		season = Season.find_by_sport_and_year(params[:sport], params[:year].to_i);

		results = season.results.map {|result|
			return_data = {
				owner: result.user.name,
				wins: result.wins,
				losses: result.losses,
				ties: result.ties,
				place: result.place
			}

			return_data[:name] = result.team_name if !@user.nil?

			return_data[:points] = result.points if params[:sport] == 'football'

			return_data
		}

		results.sort_by! {|result| result[:place]}

		json_return = {
			results: results,
			isFinal: !season.championship_score.nil?
		}

		json_return[:leagueName] = season.league_name if !@user.nil?

		json_return.to_json
	end

	post '/api/:sport/results/:year' do
		season_json = JSON.parse(request.body.read)
		result_class = params[:sport] == 'football' ? FootballResult : BaseballResult 

		results = []
		season_json["results"].each {|result_json|
			user = User.find_by_name(result_json["owner"])
			result_data = {
				team_name: result_json["teamName"],
				wins: result_json["wins"],
				losses: result_json['losses'],
				ties: result_json['ties'],
				place: result_json['place'],
				user: user
			}

			result_data[:points] = result_json['points'] if params[:sport] == 'football'

			results.push(result_class.new(result_data))
		}

		season_data = {
			year: params[:year],
			sport: params[:sport],
			league_name: season_json['leagueName'],
			championship_score: season_json['championshipScore'],
			results: results
		}

		season = Season.new(season_data)
		season.save!

		{
			success:true
		}.to_json
	end
end