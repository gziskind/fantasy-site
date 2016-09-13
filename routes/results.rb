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

	get '/:sport/results/career' do
		event "#{params[:sport].capitalize}CareerResults"
		@header_index = params[:sport]

		erb :careerStandings
	end

	get '/baseball/results/roto' do 
		event 'Roto'
		@header_index = 'baseball'

		erb :roto
	end

	get '/football/results/current' do
		event 'Zender'
		@header_index = 'football'

		erb :zenderStandings
	end

	# API Calls
	get '/api/:sport/results/career' do
		result_class = FootballResult
		if params[:sport] == 'baseball'
			result_class = BaseballResult
		end

		user_standings = {}
		results = result_class.all
		results.each {|result|
			user_id = result.user.name

			if user_standings[user_id].nil?
				user_standings[user_id] = {
					wins: 0,
					losses: 0,
					ties: 0,
					points: 0
				}
			end

			user_standings[user_id][:wins] += result.wins
			user_standings[user_id][:losses] += result.losses
			user_standings[user_id][:ties] += result.ties
			user_standings[user_id][:points] += result.points if params[:sport] == 'football'
		}

		user_standings.each_value {|user_standing|
			wins = user_standing[:wins]
			ties = user_standing[:ties]
			losses = user_standing[:losses]

			user_standing[:winPercentage] = (wins + (ties/2.0))/(wins + losses + ties)
		}

		user_standings.to_json
	end

	get '/api/baseball/results/roto' do
		stats = RotoStat.all

		stats.sort_by! {|stat| stat.total_points}
		stats.reverse!

		stats.to_json
	end

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

	get '/api/football/results/current' do
		season = Season.find_by_sport_and_year('football',2015)

		zender_results = {}
		season.results.each{|result|
			zender_results[result.user.name] = {
				wins: result.wins,
				losses: result.losses,
				ties: result.ties,
				points: result.points,
				points_wins: 0,
				points_losses: 0
			}

			zender_results[result.user.name][:team_name] = result.team_name if !@user.nil?
		}

		season.week_results.each {|week_result|
			team_results = []
			week_result.matchups.each{|matchup|
				team_results.push(matchup.team_results[0])
				team_results.push(matchup.team_results[1])
			}

			team_results.sort_by! {|team_result| team_result[:points]}
			team_results.reverse!

			team_results.each_with_index {|team_result,index|
				if(index < 6)
					zender_results[team_result.user.name][:points_wins] += 1
				else
					zender_results[team_result.user.name][:points_losses] += 1
				end
			}
		}

		zender_results.to_json
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