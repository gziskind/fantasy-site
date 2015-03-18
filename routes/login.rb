class FantasyServer 

	# API Calls
	post '/api/login' do
		login = JSON.parse(request.body.read)

		username = login["name"]
		password = Digest::MD5.hexdigest(login["password"]) if login["password"]
		event '/api/login', username

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
		event '/api/changePassword'
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
end