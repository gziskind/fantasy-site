class FantasyServer 

	DEFAULT_IMAGE_URL = "/img/empty-image.jpg"

	# Views
	get '/profiles', :auth => :user do 
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
	get '/api/profiles/:user', :auth => :user do
		user = User.find_by_name(params[:user])

		roles = user.roles.map {|role|
			role.name
		}

		results = Result.find_all_by_user_id(user._id)
		results.sort_by! {|result| [result.season.year, result.season.sport]}
		results.reverse!

		image_url = user.image_url
		image_url = DEFAULT_IMAGE_URL if image_url.nil?

		results_json = results.map {|result|
			sport = nil
			if result.class == BaseballResult
				sport = 'baseball' 
			else
				sport = 'football'
			end

			json = {
				sport: sport,
				year: result.season.year,
				place: result.place,
				record: "#{result.wins}-#{result.losses}-#{result.ties}"
			}

			json[:points] = result.points if sport == 'football'
			json
		}

		team_names = TeamName.find_all_by_owner_id(user._id);
		team_names_json = team_names.map {|team_name|
			rating = get_total_rating(team_name);

			{
				team_name: team_name.name,
				sport: team_name.sport,
				rating: rating
			}
		}

		all_records = FantasyRecord.all
		records = all_records.select {|record|
			record.record_holders.any? { |record_holder|  
				record_holder.user == user
			}
		}

		records_json = records.map {|record|
			index = record.record_holders.find_index { |record_holder|
				record_holder.user == user
			}

			{
				type: record.type,
				record: record.record,
				sport: record.sport,
				value: record.value,
				year: record.record_holders[index].year
			}
		}

		{
			roles: roles,
			imageUrl: image_url,
			tagline: 'Something',
			results: results_json,
			team_names: team_names_json,
			records: records_json
		}.to_json
	end

	post '/api/profiles/:user/image', :auth => :user do
		if @user.name == params[:user]
			image_json = JSON.parse(request.body.read)
			@user.image_url = image_json["imageUrl"]
			@user.save!

			{
				success:true
			}.to_json
		else
			redirect '/unauthorized'
		end
	end

	delete '/api/profiles/:user/image', :auth => :user do
		if @user.name == params[:user]
			@user.image_url = nil
			@user.save!

			{
				success:true,
				imageUrl: DEFAULT_IMAGE_URL
			}.to_json
		else
			redirect '/unauthorized'
		end
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