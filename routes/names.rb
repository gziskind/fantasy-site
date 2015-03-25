class FantasyServer 

	# Views
	get '/:sport/names', :auth => :user do 
		event "#{params[:sport].capitalize}Names"
		@sport = params[:sport];
		@header_index = @sport;

		role = Role.find_by_name @sport
		users = User.all

		@users = []
		users.each {|user|
			if user.roles.include? role
				@users.push(user.name)
			end
		}

		@users.sort!

		erb :names
	end


	# API Calls
	get '/api/:sport/names', :auth => :user do
		users = User.all

		team_names = []

		users.each{|user|
			names = TeamName.find_all_by_sport_and_owner_id(params[:sport], user._id)
			if names.length > 0
				names.sort_by! { |name| 
					if name.year.nil?
						name.created_at
					else
						Time.new(name.year)
					end
				}

				names.reverse!
				recent_name = names[0]

				total_rating = get_total_rating(recent_name)

				team_name_info = {
					owner: user.name,
					teamName: recent_name.name,
					rating: total_rating
				}

				if is_user?
					userRating = Rating.find_by_team_name_id_and_user_id(recent_name._id, @user._id)
					team_name_info[:myRating] = userRating.rating if !userRating.nil?
				end

				team_names.push(team_name_info)
			end
		}

		team_names.sort_by! {|name| name[:owner]}

		team_names.to_json
	end

	get '/api/:sport/names/:user', :auth => :user do
		user = User.find_by_name(params[:user]);
		names = TeamName.find_all_by_sport_and_owner_id(params[:sport], user._id);

		names.sort_by! { |name| 
			if name.year.nil?
				name.created_at
			else
				Time.new(name.year)
			end
		}
		names.reverse!

		names.map! {|name|
			total_rating = get_total_rating(name)

			team_name_info = {
				owner: user.name,
				teamName: name.name,
				rating: total_rating
			}
			if name.year.nil?
				team_name_info[:year] = name.created_at.year
			else
				team_name_info[:year] = name.year
			end


			if is_user?
				userRating = Rating.find_by_team_name_id_and_user_id(name._id, @user._id)
				team_name_info[:myRating] = userRating.rating if !userRating.nil?
			end

			team_name_info
		}

		names.to_json
	end

	post '/api/:sport/names/rating', :auth => :user do
		rating_json = JSON.parse(request.body.read)

		owner = User.find_by_name rating_json['owner']
		team_name = TeamName.find_by_sport_and_name_and_owner_id(params[:sport], rating_json['teamName'], owner._id)
		rating = Rating.find_by_team_name_id_and_user_id(team_name._id, @user._id)
		rating = Rating.new() if rating.nil?

		rating.rating = rating_json['myRating']
		rating.team_name = team_name
		rating.user = @user

		rating.save!

		total_rating = get_total_rating team_name

		{
			success:true,
			totalRating: total_rating
		}.to_json
	end

	post '/api/:sport/names/:user', :auth => :user do
		name_json = JSON.parse(request.body.read)

		current_team_name = TeamName.find_by_sport_and_name_and_owner_id(params[:sport], name_json["teamName"], @user._id);

		if current_team_name.nil?
			team_name = TeamName.new({
				owner: @user,
				name: name_json["teamName"],
				sport: params[:sport],
				year: name_json["year"]
			})

			team_name.save!

			{
				success: true
			}.to_json
		else
			{
				success: false,
				message: "Team name already exists."
			}.to_json
		end
	end

	# Helper Methods
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