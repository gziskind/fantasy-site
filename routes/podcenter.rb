require 'dropbox_sdk'

class FantasyServer 
	# Views
	get '/podcenter', :auth => :user do
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
	post '/api/podcenter' do
		token = settings.dropbox_token
		client = DropboxClient.new(token)

		file = params['file'][:tempfile]
		filename = params['file'][:filename]

		name = "/podcasts/#{filename}"

		client.put_file name, file
		url = client.media name

		podcast = Podcast.new({
			name: filename,
			url: url["url"]
		})

		podcast.save!

		url.to_json
	end
end