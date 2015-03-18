class FantasyServer 
	# Views
	get '/admin/events', :auth => :admin do
		event 'AdminEvents'
		@header_index = 'admin'
		erb :adminEvents
	end



	# API Calls
end