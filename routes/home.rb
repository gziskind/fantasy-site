class FantasyServer 

	# Views
	# Home page
	get '/' do 
		event '/'

		championship_results  = Result.find_all_by_place(1)
		last_place_results = Result.find_all_by_place(12)
		team_names = TeamName.all

		championships = {}
		championship_results.each {|result|
			if !result.season.championship_score.nil?
				if championships.include? result.user.name
					championships[result.user.name]+= 1
				else
					championships[result.user.name] = 1
				end
			end
		} 

		@championships = championships.sort_by {|name, count| count }
		@championships.reverse!
		@championships = @championships.slice(0,5)

		last_places = {}
		last_place_results.each {|result|
			if !result.season.championship_score.nil?
				if last_places.include? result.user.name
					last_places[result.user.name]+= 1
				else
					last_places[result.user.name] = 1
				end
			end
		}

		@last_places = last_places.sort_by {|name, count| count}
		@last_places.reverse!
		@last_places = @last_places.slice(0,5)

		@team_names = []
		team_names.each {|team_name|
			rating = get_total_rating(team_name)

			if !rating.nil?
				@team_names.push({
					name: team_name.name,
					owner: team_name.owner.name,
					rating: get_total_rating(team_name)
				})
			end
		}

		@team_names.sort_by! {|team_name| team_name[:rating]}

		erb :index
	end

	get '/unauthorized' do
		event '/unauthorized'

		erb :unauthorized
	end

	def get_total_rating(team) 
		total_rating = 0
		ratings = Rating.find_all_by_team_name_id(team._id)
		ratings.each {|rating|
			total_rating += rating.rating
		}
		if ratings.length > 0
			total_rating = total_rating / ratings.length.to_f
		else
			total_rating = nil
		end

		total_rating
	end


end