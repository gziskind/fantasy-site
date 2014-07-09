class FantasyServer 

	# Views
	get '/:sport/records' do
		@sport = params[:sport];
		@header_index = @sport;

		erb :records
	end


	# API Calls
	get '/api/:sport/records' do
		records = FantasyRecord.find_all_by_sport_and_confirmed(params[:sport], true);

		results = records.map {|result|
			owners = result.owners.map {|owner|
				{
					name: owner.name
				}
			}

			{
				type: result.type,
				record: result.record,
				value: result.value,
				years: result.years,
				owners: owners 
			}
		}

		results.sort_by! {|result| [result[:type], result[:record]]}

		results.to_json
	end

	post '/api/:sport/record', :auth => :user do
		record_json = JSON.parse(request.body.read);

		owners = []
		record_json["owners"].each {|owner|
			owners.push(User.find_by_name(owner["name"]));
		}

		record = FantasyRecord.new({
			type: record_json['type'],
			record: record_json["record"],
			value: record_json["value"],
			years: record_json["years"],
			sport: params[:sport],
			confirmed: false,
			submitted_by: @user,
			owners: owners
		})

		record.save!

		{
			success:true,
		}.to_json
	end

	get '/api/:sport/years' do
		seasons = Season.find_all_by_sport(params[:sport]);

		results = []
		seasons.each {|season|
			results.push({
				year: season.year
			});
		}

		results.sort_by! {|result| result[:year]}.to_json
	end

end