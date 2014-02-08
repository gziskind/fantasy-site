require 'sinatra/base'

class FantasyServer < Sinatra::Base

	def self.start
		run!
	end

	get '/' do
		erb :index
	end
end
