require 'sinatra/base'
require 'json'
require 'digest/md5'
require_relative 'model'
require_relative 'helpers'

class FantasyServer < Sinatra::Base

	set :sessions => true

	register do
		def auth(type) 
			condition do
				redirect '/unauthorized' unless send("is_#{type}?")
			end
		end
	end

	def self.start
		init_db

		run!
	end

	def self.init_db
		MongoMapper.connection = Mongo::Connection.new(settings.db_host, settings.db_port)
		MongoMapper.database = settings.database
	end

	# Home page
	get '/' do 
		erb :index
	end

	helpers Helpers
end

# Include routes
require_relative 'routes/login'
require_relative 'routes/results'
require_relative 'routes/admin'
require_relative 'routes/records'
require_relative 'routes/names'
require_relative 'routes/champions'
require_relative 'routes/user'
