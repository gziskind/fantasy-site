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
		@header_index = @sport;
		@seasons = [2013,2012,2011,2010];

		erb :results
	end

	get '/:sport/records' do
		@sport = params[:sport];
		@header_index = @sport;
		@users = ['Greg','Greg2','Greg3'];

		erb :records
	end

	get '/:sport/names' do 
		@sport = params[:sport];
		@header_index = @sport;
		@users = ['Greg','Greg2','Greg3','Greg4'];

		erb :names
	end

	get '/polls/:type' do 
		@header_index = 'polls'
		@poll_type = params[:type]

		if(@poll_type == 'current') 
			@polls = [{
				id: 1,
				name: 'Current Poll'
			}]
		else 
			@polls = [{
					id: 2,
					name: 'Poll 2'
				},{
					id: 3,
					name: 'Poll 3'
				}, {
					id: 4,
					name: 'Poll 4'
				}
			];
		end

		erb :polls
	end



	get '/api/:sport/results/:year' do
		[{
			name: "Greg's #{params[:sport].capitalize} Team",
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

	get '/api/:sport/records' do
		[{
			record:'Most Wins',
			name: "Greg's #{params[:sport]} Team",
			owner: 'Greg',
			value: 56,
			year: 2013
		},{
			record:'Most Loses',
			name: "Carrie's Team",
			owner: 'Carrie',
			value: 54,
			year: 2013
		}].to_json
	end

	get '/api/:sport/records/:user' do
		[{
			record:'Most Wins',
			name: "Greg's #{params[:sport]} Team",
			owner: params[:user],
			value: 56,
			year: 2013
		}].to_json
	end

	get '/api/:sport/names' do
		[{
			owner: 'Greg',
			teamName: "Greg's #{params[:sport].capitalize} Team"
		},{
			owner: 'Carrie',
			teamName: "Carrie's Team"
		},{
			owner: 'Someone Else',
			teamName:"Else's Team"
		}].to_json
	end

	get '/api/:sport/names/:user' do
		[{
			year:2013,
			teamName: "#{params[:user]}'s #{params[:sport].capitalize} Team"
		},{
			year: 2012,
			teamName: 'Team 2'
		}, {
			year: 2011,
			teamName: 'Team 3'
		}].to_json
	end

	get '/api/polls/:poll_id' do
		if(params[:poll_id] == '1') 
			{
				name: 'Current Poll',
				results: false,
				questions: [
					{
						question: 'What would you choose?',
						type: 'multipleChoice',
						options: {
							'Option A' => nil,
							'Option B' => nil,
							'Option C' => nil,
							'Option D' => nil
						}
					}, {
						question: 'What about this time?',
						type: 'multipleChoice',
						options: {
							'Answer A' => nil,
							'Answer B' => nil
						}
					}
				]
			}.to_json
		else
			{
				name: 'Poll 2',
				results: true,
				questions: [
					{
						question: 'What would you choose?',
						type: 'multipleChoice',
						options: {
							'Option A' => 9,
							'Option B' => 2,
							'Option C' => 0,
							'Option D' => 1
						}
					}
				]
			}.to_json
		end
	end

	helpers do
		def isBaseballActive
			if @header_index == 'baseball'
				return 'active'
			else
				return ''
			end
		end

		def isFootballActive 
			if @header_index == 'football'
				return 'active'
			else
				return ''
			end
		end

		def isPollActive
			if @header_index == 'polls'
				return 'active'
			else
				return ''
			end
		end
	end
end
