class FantasyServer 
	# Views
	get '/admin/events', :auth => :admin do
		@header_index = 'admin'
		erb :adminEvents
	end


	# API Calls
	get '/api/events/summary' do
		events = Event.all

		event_types = {}
		event_summaries = {}

		events.each { |event|
			event_types[event.event] = 1

			if(!event_summaries[event.username]) 
				event_summaries[event.username] = {}
			end

			event_summaries[event.username] = {

			}
		}

		{
			eventTypes: event_types.keys,
			eventSummaries: []
		}.to_json
	end

	get '/api/events/live/:page' do
		events = Event.paginate({
			order: :time.desc,
			per_page: 20,
			page: params[:page]
		});

		results = events.map {|event|
			{
				username: event.username,
				event: event.event,
				time: event.time
			}
		}

		{
			count: Event.count,
			events: results
		}.to_json
	end
end