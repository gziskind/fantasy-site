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
		MongoMapper.connection = Mongo::Connection.new('localhost')
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
		@users = ['Greg','Greg2','Greg3'];

		erb :records
	end

	get '/:sport/names' do 
		@sport = params[:sport];
		@header_index = @sport;

		users = User.all

		@users = users.map {|user|
			user.username
		}

		erb :names
	end

	get '/:sport/champions' do
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
				winner: winner.user.username,
				record: winner.record,
				result: season.championship_score,
				runner_up: runner_up.user.username
			})

			@champions.sort_by! {|champion| champion[:year]}
			@champions.reverse!
		}

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
		erb :changePassword
	end 

	get '/admin/users', :auth => :admin do
		erb :users
	end

	# AJAX Calls

	get '/api/:sport/results/:year' do
		season = Season.find_by_sport_and_year(params[:sport], params[:year].to_i);

		results = season.results.map {|result|
			{
				name: result.team_name,
				owner: result.user.username,
				wins: result.wins,
				losses: result.losses,
				ties: result.ties,
				place: result.place
			}
		}

		results.sort_by! {|result| result[:place]}

		results.to_json
	end

	get '/api/:sport/records' do
		records = FantasyRecord.find_all_by_sport(params[:sport]);

		results = records.map {|result|
			{
				record: result.record,
				name: result.team_name,
				owner: result.owner.username,
				value: result.value,
				year: result.season
			}
		}

		results.to_json
	end

	get '/api/:sport/records/:user' do
		owner = User.find_by_username(params[:user]);
		records = FantasyRecord.find_all_by_sport(params[:sport]);

		records.select! {|item| 
			item.owner.username == owner.username
		}

		results = records.map {|result|
			{
				record: result.record,
				name: result.team_name,
				owner: result.owner.username,
				value: result.value,
				year: result.season
			}
		}

		results.to_json
	end

	get '/api/:sport/names' do
		[{
			owner: 'Greg',
			teamName: "Greg's #{params[:sport].capitalize} Team"
		},{
			owner: 'Carrie',
			teamName: "Carrie's Team"
		},{
			owner: 'Someone Else',
			teamName:"Else's Team"
		}].to_json
	end

	get '/api/:sport/names/:user' do
		user = User.find_by_username(params[:user]);
		names = TeamName.find_all_by_sport_and_owner_id(params[:sport], user._id);

		names.sort_by! {|name| name.created_at}

		names.map! {|name|
			{
				year: name.created_at.year,
				teamName: name.name
			}
		}

		names.to_json
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
	end
end
