require 'sinatra/base'
require 'json'
require 'digest/md5'
require_relative 'model'

class FantasyServer < Sinatra::Base

	set :sessions => true

	register do
		def auth(type) 
			condition do
				redirect '/unauthorized' unless send("is_#{type}?")
			end
		end
	end

	before do
		@user = User.find_by_id(session[:user_id])
	end

	post '/api/login' do
		login = JSON.parse(request.body.read)

		username = login["name"]
		password = Digest::MD5.hexdigest(login["password"]) if login["password"]

		user = User.find_by_username_and_password(username, password);
		
		if(user)
			session[:user_id] = user.id
			user.public_user.to_json
		else
			{
				error:"Invalid Login"
			}.to_json
		end
	end

	post '/api/logout', :auth => :user do
		puts "Logging out #{@user.username}"
		@user = nil
		session[:user_id] = nil
	end

	post '/api/changePassword', :auth => :user do
		passwordChange = JSON.parse(request.body.read)
		password_hash = Digest::MD5.hexdigest(passwordChange['currentPassword']);
		if(password_hash != @user.password) 
			{
				success:false,
				message:"Invalid Password"
			}.to_json
		elsif(passwordChange['newPassword1'] != passwordChange['newPassword2']) 
			{
				success:false,
				message:"Passwords do not match"
			}.to_json
		else
			@user.password = Digest::MD5.hexdigest(passwordChange['newPassword1']);
			@user.save!

			{
				success:true,
				message: "Password Change successful"
			}.to_json
		end
	end

	def self.start
		init_db

		run!
	end

	def self.init_db
		MongoMapper.connection = Mongo::Connection.new(settings.db_host, settings.db_port)
		MongoMapper.database = settings.database
	end

	# Home pages

	get '/' do 
		erb :index
	end

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

	get '/:sport/records' do
		@sport = params[:sport];
		@header_index = @sport;

		erb :records
	end

	get '/:sport/names' do 
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

	get '/:sport/champions' do
		@header_index = params[:sport]
		@sport = params[:sport]

		@champions = []

		seasons = Season.find_all_by_sport(@sport);
		@seasons = seasons.map {|season|
			winner_index = season.results.find_index {|result|
				result.place == 1
			}

			winner = season.results[winner_index]

			runner_up_index = season.results.find_index {|result|
				result.place == 2
			}
			runner_up = season.results[runner_up_index]

			@champions.push({
				year: season.year,
				team_name: winner.team_name,
				winner: winner.user.name,
				record: winner.record,
				result: season.championship_score,
				runner_up: runner_up.user.name
			}) if !season.championship_score.nil?

		}

		@champions.sort_by! {|champion| champion[:year]}
		@champions.reverse!

		erb :champions
	end

	get '/polls/:type' do 
		@header_index = 'polls'
		@poll_type = params[:type]

		if(@poll_type == 'current') 
			@polls = [{
				id: 1,
				name: 'Current Poll'
			}]
		else 
			@polls = [{
					id: 2,
					name: 'Poll 2'
				},{
					id: 3,
					name: 'Poll 3'
				}, {
					id: 4,
					name: 'Poll 4'
				}
			];
		end

		erb :polls
	end

	get '/user/changePassword', :auth => :user do
		@header_index = 'admin'
		erb :changePassword
	end 

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

	# AJAX Calls

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
						place: result.place
					}

					if params[:sport] == 'baseball'
						return_data[:ties] = result.ties
					else
						return_data[:points] = result.points
					end

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
				place: result.place
			}

			if params[:sport] == 'baseball'
				return_data[:ties] = result.ties
			else
				return_data[:points] = result.points
			end

			return_data
		}

		results.sort_by! {|result| result[:place]}

		results.to_json
	end

	get '/api/:sport/records' do
		records = FantasyRecord.find_all_by_sport_and_confirmed(params[:sport], true);

		results = records.map {|result|
			owners = result.owners.map {|owner|
				{
					name: owner.name
				}
			}

			{
				type: result.type,
				record: result.record,
				value: result.value,
				years: result.years,
				owners: owners 
			}
		}

		results.sort_by! {|result| [result[:type], result[:record]]}

		results.to_json
	end

	post '/api/:sport/record', :auth => :user do
		record_json = JSON.parse(request.body.read);

		owners = []
		record_json["owners"].each {|owner|
			owners.push(User.find_by_name(owner["name"]));
		}

		record = FantasyRecord.new({
			type: record_json['type'],
			record: record_json["record"],
			value: record_json["value"],
			years: record_json["years"],
			sport: params[:sport],
			confirmed: false,
			submitted_by: @user,
			owners: owners
		})

		record.save!

		{
			success:true,
		}.to_json
	end

	get '/api/:sport/years' do
		seasons = Season.find_all_by_sport(params[:sport]);

		results = []
		seasons.each {|season|
			results.push({
				year: season.year
			});
		}

		results.sort_by! {|result| result[:year]}.to_json
	end

	get '/api/:sport/names' do
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

	get '/api/:sport/names/:user' do
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
				year: name.created_at.year,
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

	get '/api/polls/:poll_id' do
		if(params[:poll_id] == '1') 
			{
				name: 'Current Poll',
				results: false,
				questions: [
					{
						question: 'What would you choose?',
						type: 'multipleChoice',
						options: {
							'Option A' => nil,
							'Option B' => nil,
							'Option C' => nil,
							'Option D' => nil
						}
					}, {
						question: 'What about this time?',
						type: 'multipleChoice',
						options: {
							'Answer A' => nil,
							'Answer B' => nil
						}
					}
				]
			}.to_json
		else
			{
				name: 'Poll 2',
				results: true,
				questions: [
					{
						question: 'What would you choose?',
						type: 'multipleChoice',
						options: {
							'Option A' => 9,
							'Option B' => 2,
							'Option C' => 0,
							'Option D' => 1
						}
					}
				]
			}.to_json
		end
	end

	get '/api/:sport/allusers' do
		role = Role.find_by_name(params[:sport])
		users = User.all

		results = []
		users.each {|user|
			results.push({
				name: user.name
			}) if user.roles.include? role
		}

		results.to_json
	end

	get '/api/admin/users', :auth => :admin do
		users = User.all

		users.map! {|user|
			user.public_user
		}

		users.to_json
	end

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
			roles: roles,
			password: password_hash
		}

		User.new(user_data).save!
	end

	post '/api/admin/results', :auth => :admin do
		season_json = JSON.parse(request.body.read)
		season = Season.find_by_sport_and_year(season_json["sport"], season_json["year"]);

		season.championship_score = season_json["championship_score"];
		results = []
		season_json["results"].each {|result_json|
			user = User.find_by_name(result_json["owner"])
			result = {
				team_name: result_json["name"],
				wins: result_json["wins"],
				losses: result_json["losses"],
				place: result_json["place"],
				user: user
			}

			if season_json["sport"] == 'football'
				result[:points] = result_json["points"]
				results.push(FootballResult.new(result));
			else
				result[:ties] = result_json["ties"]
				results.push(BaseballResult.new(result));
			end
		}

		season.results = results;
		season.save!

		{
			success:true,
			message:"Results Updated"
		}.to_json
	end

	get '/api/admin/:sport/records', :auth => :admin do
		records = FantasyRecord.find_all_by_sport_and_confirmed(params[:sport], false);

		results = records.map {|result|
			owners = result.owners.map {|owner|
				{
					name: owner.name
				}
			}

			{
				type: result.type,
				id: result._id,
				record: result.record,
				value: result.value,
				years: result.years,
				owners: owners,
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

	helpers do
		def isBaseballActive
			if @header_index == 'baseball'
				return 'active'
			else
				return ''
			end
		end

		def isFootballActive 
			if @header_index == 'football'
				return 'active'
			else
				return ''
			end
		end

		def isPollActive
			if @header_index == 'polls'
				return 'active'
			else
				return ''
			end
		end

		def isAdminActive
			if @header_index == 'admin'
				return 'active'
			else
				return ''
			end
		end

		def currentYear(sport)
			seasons = Season.find_all_by_sport(sport);
			seasons = seasons.map {|season|
				season.year
			}

			seasons.sort!.reverse!
			seasons[0]
		end

		def is_user?
			@user != nil
		end

		def is_admin?
			admin = false
			@user.roles.each {|role|
				if role.name == "admin"
					admin = true
				end
			} if @user != nil

			admin
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
end
