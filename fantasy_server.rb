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
	end

	def self.start
		use Rack::Session::Moneta, key: 'rack.session',
			expire_after: 2592000,
			store: Moneta.new(:Redis, expires: true, :host => settings.redis_host, :port => settings.redis_port, :password => settings.redis_password)

		init_db

		run!
	end

	def self.init_db
		MongoMapper.connection = Mongo::Connection.new(settings.db_host, settings.db_port)
		MongoMapper.database = settings.database
		MongoMapper.database.authenticate(settings.db_user, settings.db_password) if settings.db_user && settings.db_password
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
