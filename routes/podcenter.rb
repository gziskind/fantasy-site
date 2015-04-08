require 'dropbox_sdk'

class FantasyServer 
	# Views
	get '/podcenter', :auth => :user do
		event "Podcenter"

		@header_index = 'podcenter'

		podcasts = Podcast.all
		podcasts.sort_by! {|podcast|
			podcast.created_at
		}
		podcasts.reverse!

		@podcasts = podcasts

		erb :podcenter
	end


	# API Calls
	post '/api/podcenter', :auth => :admin do
		token = settings.dropbox_token
		client = DropboxClient.new(token)

		file = params['file'][:tempfile]
		filename = params['file'][:filename]

		realname = params['name'];

		name = "/podcasts/#{filename}"

		client.put_file name, file
		url = client.media name

		podcast = Podcast.new({
			name: realname,
			url: url["url"]
		})

		podcast.save!

		url.to_json
	end
end