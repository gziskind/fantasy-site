class FantasyServer 

	# Views
	# Home page
	get '/' do 
		event 'Home'

		erb :index
	end

	get '/unauthorized' do
		event 'Unauthorized'

		erb :unauthorized
	end

	# API Calls
	get '/api/landing' do
		championship_results  = Result.find_all_by_place(1)
		last_place_results = Result.find_all_by_place(12)
		team_names = TeamName.all
		records = FantasyRecord.find_all_by_confirmed(true)

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
					rating: rating.round(2)
				})
			end
		}

		@team_names.sort_by! {|team_name| team_name[:rating]}
		best_team_names = @team_names.slice(0,10)
		worst_team_names = @team_names.reverse.slice(0,10)

		@new_team_names = []
		new_team_names = team_names.sort_by {|team_name| team_name.created_at}
		new_team_names.each {|team_name| 
			rating = get_total_rating(team_name)
			userRating = Rating.find_by_team_name_id_and_user_id(team_name._id, @user._id) if !@user.nil?

			new_team_name = {
				teamName: team_name.name,
				owner: team_name.owner.name,
				rating: rating,
				sport: team_name.sport
			}
			new_team_name[:myRating] = userRating.rating if !userRating.nil?


			@new_team_names.push(new_team_name)
		}
		@new_team_names.reverse!
		@new_team_names = @new_team_names.slice(0,10)

		@new_records = []
		records.each {|record|
			record_holders = record.record_holders.map {|record_holder| record_holder.user.name}
			record_holders = ['Various'] if record_holders.length == 0

			@new_records.push({
				sport: record.sport.capitalize,
				type: record.type.capitalize,
				record: record.record,
				value: record.value,
				owner: record_holders.join(", "),
				created_at: record.created_at
			}) 
		}
		@new_records.sort_by! {|record| record[:created_at].nil? ? Date.new(0) : record[:created_at]  }
		@new_records.reverse!
		@new_records = @new_records.slice(0,10)

		result = {
			championships: @championships,
			lastPlaces: @last_places,
		}
		if(!@user.nil?)
			result[:bestTeamNames] = best_team_names
			result[:worstTeamNames] = worst_team_names
			result[:newTeamNames] = @new_team_names
			result[:newRecords] = @new_records
		end
		
		result.to_json
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