require 'sinatra/base'

class FantasyServer < Sinatra::Base

	def self.start
		run!
	end

	get '/:sport/results' do
		@sport = params[:sport];
		@seasons = [2013,2012,2011,2010];

		erb :results
	end

	get '/:sport/records' do
		@sport = params[:sport];
		@users = ['Greg','Greg2','Greg3'];

		erb :records
	end

	get '/:sport/names' do 
		@sport = params[:sport];
		@users = ['Greg','Greg2','Greg3','Greg4'];

		erb :names
	end

	helpers do
		def isBaseballActive
			if @sport == 'baseball'
				return 'active'
			else
				return ''
			end
		end

		def isFootballActive 
			if @sport == 'football'
				return 'active'
			else
				return ''
			end
		end
	end
end
