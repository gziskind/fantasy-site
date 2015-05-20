class FantasyServer
	
	before do
		@user = User.find_by_id(session[:user_id])
		if(!@user.nil?)
			response.set_cookie("currentUser", :value => {
				id: @user._id,
				username: @user.username,
				roles: @user.roles,
				name: @user.name
			}.to_json, :path => '/')
		end
	end


	# Views
	get '/user/changePassword', :auth => :user do
		event "UserChangePassword"
		@header_index = 'admin'
		erb :changePassword
	end 


	# API Calls
	get '/api/allusers/:sport' do
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

	get '/api/allusers' do
		users = User.all

		results = []
		users.each {|user|
			roles = user.roles.map {|role|
				role.name
			}

			results.push({
				name: user.name,
				roles: roles
			})
		}

		results.to_json
	end
end