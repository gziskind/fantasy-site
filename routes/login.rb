class FantasyServer 

	# Views
	get '/user/changePassword', :auth => :user do
		event "UserChangePassword"
		@header_index = 'user'
		erb :changePassword
	end 

	get '/user/notifications', :auth => :user do
		event "UserNotifications"
		@header_index = 'user'
		erb :notifications
	end

	# API Calls
	post '/api/login' do
		login = JSON.parse(request.body.read)

		username = login["name"].downcase
		password = Digest::MD5.hexdigest(login["password"]) if login["password"]
		event 'Login', username

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
		event 'ChangePassword'
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

	get '/api/user/notifications', :auth => :user do
		notifications = {
			homeruns_team: @user.notification_homeruns_team.nil? ? true : @user.notification_homeruns_team,
			steals_team: @user.notification_steals_team.nil? ? true : @user.notification_steals_team
		}

		notifications.to_json
	end

	post '/api/user/notifications', :auth => :user do
		event "ChangeNotifications"

		notifications = JSON.parse(request.body.read)

		@user.notification_homeruns_team = notifications["homeruns_team"]
		@user.notification_steals_team = notifications["steals_team"]

		@user.save!

		{
			success:true,
			message: "Notifications updated."
		}.to_json
	end
end