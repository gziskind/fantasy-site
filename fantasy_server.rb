require 'sinatra/base'
require 'json'

class FantasyServer < Sinatra::Base

	def self.start
		run!
	end

	get '/' do 
		erb :index
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

	get'/api/results/:year' do
		[{
			name: "Greg's Team",
			owner: 'Greg',
			wins: 125,
			losses: 70,
			ties: 15
		},{
			name: "Carrie's Team",
			owner: 'Carrie',
			wins: 101,
			losses: 97,
			ties: 12
		},{
			name: "Albus's Team(#{params[:year]})",
			owner: 'Albus',
			wins: 80,
			losses: 95,
			ties: 8
		}].to_json
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
