class FantasyServer 

	DEFAULT_IMAGE_URL = "/img/empty-image.jpg"

	# Views
	get '/profiles', :auth => :user do 
		event "Profiles"
		@header_index = 'profiles';

		users = User.all

		@users = []
		users.each {|user|
			@users.push(user.name) if user.roles.size > 0
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
				record: "#{result.wins}-#{result.losses}-#{result.ties}",
				finalized: result.season.championship_score.nil? ? false : true
			}

			json[:points] = result.points if sport == 'football'
			json
		}

		team_names = TeamName.find_all_by_owner_id(user._id);
		team_names_json = team_names.map {|team_name|

			{
				team_name: team_name.name,
				sport: team_name.sport,
				rating: team_name.total_rating
			}
		}

		all_records = FantasyRecord.find_all_by_confirmed(true)
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

		drafted = DraftPick.find_all_by_user_id(user._id)
		drafted_map = {}
		drafted.each {|pick|
			name = "#{pick.player.first_name} #{pick.player.last_name}"
			if drafted_map[name].nil?
				drafted_map[name] = {
					count: 0,
					position: pick.position,
					first_name: pick.player.first_name,
					last_name: pick.player.last_name,
					sport: pick.player.sport
				} 
			end
			drafted_map[name][:count] += 1
		}

		drafted_json = drafted_map.map {|name, pick| pick}
		drafted_json.sort_by! {|pick| [-pick[:count], pick[:sport], pick[:position]]}

		{
			roles: roles,
			imageUrl: image_url,
			bio: user.bio,
			results: results_json,
			team_names: team_names_json,
			records: records_json,
			most_drafted: drafted_json
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

	
end