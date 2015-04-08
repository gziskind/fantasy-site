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
	get '/api/podcenter/:podname', :auth => :user do
		name = params[:podname]
		podcast = Podcast.find_by_name name

		token = settings.dropbox_token
		client = DropboxClient.new(token)

		url = client.media podcast.path

		url.to_json
	end

	post '/api/podcenter', :auth => :admin do
		token = settings.dropbox_token
		client = DropboxClient.new(token)

		file = params['file'][:tempfile]
		filename = params['file'][:filename]

		realname = params['name'];

		path = "/podcasts/#{filename}"

		client.put_file path, file
		url = client.media path

		podcast = Podcast.new({
			name: realname,
			path: path
		})

		podcast.save!

		url.to_json
	end
end