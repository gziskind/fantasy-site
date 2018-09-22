class FantasyServer 
	# Views
	get '/admin/users', :auth => :admin do
		@header_index = 'admin'
		erb :users
	end

	get '/admin/editResults', :auth => :admin do
		@header_index = 'admin'
		erb :adminResults
	end

	get '/admin/confirmRecords', :auth => :admin do
		@header_index = 'admin'
		erb :adminRecords
	end

	get '/admin/parsing', :auth => :admin do
		@header_index = 'admin'
		erb :adminParsing
	end

	get '/admin/log', :auth => :admin do
		@header_index = 'admin'
		erb :adminLog
	end

	# API Calls
	get '/api/admin/roles', :auth => :admin do
		roles = Role.all

		roles.to_json
	end

	post '/api/admin/user', :auth => :admin do
		user_json = JSON.parse(request.body.read)
		password_hash = Digest::MD5.hexdigest(user_json['password1'])

		roles = []
		user_json['roles'].each {|key,value|
			roles.push(Role.find_by_name(key)) if value
		}

		user_data = {
			username: user_json["username"],
			name: user_json["name"],
			unique_name: user_json["uniqueName"],
			roles: roles,
			password: password_hash
		}

		User.new(user_data).save!
	end

	post '/api/admin/results', :auth => :admin do
		season_json = JSON.parse(request.body.read)
		season = Season.find_by_sport_and_year(season_json["sport"], season_json["year"]);

		season.championship_score = season_json["championship_score"];
		season.save!

		results = []
		season_json["results"].each {|result_json|
			user = User.find_by_name(result_json["owner"])
			result = Result.find_by_season_id_and_user_id(season._id, user._id);

			result.place = result_json["place"]
			result.save!
		}

		{
			success:true,
			message:"Results Updated"
		}.to_json
	end

	get '/api/admin/:sport/records', :auth => :admin do
		records = FantasyRecord.find_all_by_sport_and_confirmed(params[:sport], false);

		results = records.map {|result|
			record_holders = result.record_holders.map {|record_holder|
				{
					name:record_holder.user.name,
					year: record_holder.year
				}
			}

			{
				type: result.type,
				id: result._id,
				record: result.record,
				value: result.value,
				record_holders: record_holders,
				submittedBy: result.submitted_by.name
			}
		}

		results.to_json
	end

	post '/api/admin/:sport/record/confirm', :auth => :admin do
		record_json = JSON.parse(request.body.read)

		current_record = FantasyRecord.find_by_sport_and_record_and_confirmed_and_type(params[:sport], record_json["record"], true, record_json['type'])
		if !current_record.nil?
			current_record.destroy
		end

		record = FantasyRecord.find_by_id(record_json['id']);
		record.confirmed = true;

		record.save!

		{
			success: true
		}.to_json
	end

	post '/api/admin/:sport/record/reject', :auth => :admin do
		record_json = JSON.parse(request.body.read)

		record = FantasyRecord.find_by_id(record_json['id']);

		record.destroy

		{
			success: true
		}.to_json
	end

	get '/api/admin/users', :auth => :admin do
		users = User.all

		users.map! {|user|
			user.public_user
		}

		users.to_json
	end

	post '/api/admin/users/:username/passwordreset', :auth => :admin do
		user = User.find_by_username(params[:username])

		password_hash = Digest::MD5.hexdigest('testing');
		user.password = password_hash
		user.save!

		{
			success:true
		}.to_json
	end

	delete '/api/admin/users/:username', :auth => :admin do
		user = User.find_by_username(params[:username])

		success = false
		if user.roles.length == 0
			user.destroy
			success = true
		end

		{
			success: success
		}.to_json
	end
end