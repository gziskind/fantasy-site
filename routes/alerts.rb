class FantasyServer
	
	# API Calls
	get '/api/alerts' do
		{
			admin: {
				records: {
					baseball: get_records_count('baseball'),
					football: get_records_count('football')
				}
			}
		}.to_json
	end

	def get_records_count(sport)
		FantasyRecord.find_all_by_sport_and_confirmed(sport, false).size
	end


end