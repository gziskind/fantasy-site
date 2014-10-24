class FantasyServer 

	# Views
	get '/profiles' do 
		@header_index = 'profiles';

		users = User.all

		@users = []
		users.each {|user|
			@users.push(user.name)
		}

		@users.sort!

		erb :profiles
	end


	# API Calls
	get '/api/profiles/:user/results' do
		user = User.find_by_name(params[:user])

		baseball_results = BaseballResult.find_all_by_user_id(user._id)
		football_results = FootballResult.find_all_by_user_id(user._id)

		results = {};
		results[:baseball] = get_baseball_stats(baseball_results) if !baseball_results.nil?
		results[:football] = get_football_stats(football_results) if !football_results.nil?

		results.to_json
	end

	def get_baseball_stats(results) 
		wins = 0
		losses = 0
		ties = 0
		total_finish = 0
		finishes = {}

		results.each {|result|
			wins += result.wins
			losses += result.losses
			ties += result.ties
			total_finish += result.place

			finishes[result.season.year.to_s] = {
				place: result.place,
				record: "#{result.wins} - #{result.losses} - #{result.ties}"
			} 
		}

		win_percentage = ((wins + ties/2.0) / (wins + losses + ties)).round(3)
		average_finish = (total_finish / results.size.to_f).round


		{
			"Win Percentage" => "#{win_percentage}",
			"Average Finish" => "#{get_place(average_finish)} Place",
			"results" => finishes
		}
	end

	def get_football_stats(results)
		{}
	end

	def round(number) 
		(number - 0.5).round
	end

	def get_place(place)
		if place == 1
			"1st"
		elsif place == 2
			"2nd"
		elsif place == 3
			"3rd"
		else
			"#{place}th"
		end
	end
end