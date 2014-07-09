class FantasyServer
	
	before do
		@user = User.find_by_id(session[:user_id])
	end


	# Views
	get '/user/changePassword', :auth => :user do
		@header_index = 'admin'
		erb :changePassword
	end 


	# API Calls
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
end