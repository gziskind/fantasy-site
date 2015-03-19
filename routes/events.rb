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
				event_summaries[event.username] = {
					hits: 0
				}
			end

			event_summaries[event.username][:hits] += 1
			add_event(event_summaries[event.username], event.event)
		}

		summaries = []
		event_summaries.each {|user, data|
			summary = {
				name: user
			}

			data.each {|type,count|
				summary[type] = count
			}

			summaries.push(summary)
		}

		{
			eventTypes: event_types.keys,
			eventSummaries: summaries
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

	def add_event(summary, event)
		if(!summary[event])
			summary[event] = 0
		end

		summary[event] += 1
	end
end