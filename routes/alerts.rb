class FantasyServer
	
	# API Calls
	get '/api/alerts' do
		{
			admin: {
				records: {
					baseball: get_records_count('baseball'),
					football: get_records_count('football')
				}
			},
			user: {
				changePassword: need_to_change_password
			}
		}.to_json
	end

	def get_records_count(sport)
		FantasyRecord.find_all_by_sport_and_confirmed(sport, false).size
	end

	def need_to_change_password
		if !@user.nil? && @user.password == Digest::MD5.hexdigest('testing')
			1
		end
	end

end