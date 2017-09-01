require 'sinatra/base'
require 'json'
require 'digest/md5'
require 'rack/session/moneta'
require 'sinatra/cookies'

require_relative 'model'
require_relative 'helpers'

class FantasyServer < Sinatra::Base


	register do
		def auth(type) 
			condition do
				redirect "/unauthorized?redirect=#{request.fullpath}" unless send("is_#{type}?")
			end
		end

		def token(value)
			condition do
				body = request.body.read
				if !body.empty? && JSON.parse(body)['token'] == settings.api_token
					true
				else
					halt 401, "Unauthorized"
				end
			end
		end
	end

	def self.start
		use Rack::Session::Moneta, key: 'rack.session',
			expire_after: 259200000,
			store: Moneta.new(:Redis, expires: true, :host => settings.redis_host, :port => settings.redis_port, :password => settings.redis_password)

		init_db

		run!
	end

	def self.init_db
		MongoMapper.connection = Mongo::Client.new(["#{settings.db_host}:#{settings.db_port}"], user: settings.db_user, password: settings.db_password, database: settings.database)
	end

	helpers Helpers
	helpers Sinatra::Cookies
end

# Include routes
require_relative 'routes/home'
require_relative 'routes/login'
require_relative 'routes/results'
require_relative 'routes/admin'
require_relative 'routes/records'
require_relative 'routes/names'
require_relative 'routes/champions'
require_relative 'routes/user'
require_relative 'routes/profiles'
require_relative 'routes/alerts'
require_relative 'routes/events'
require_relative 'routes/podcenter'
require_relative 'routes/draft'
require_relative 'routes/parser'
