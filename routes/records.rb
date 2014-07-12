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
			record_holders = result.record_holders.map {|record_holder|
				{
					name:record_holder.user.name,
					year: record_holder.year
				}
			}

			{
				type: result.type,
				record: result.record,
				value: result.value,
				record_holders: record_holders
			}
		}

		results.sort_by! {|result| [result[:type], result[:record]]}

		results.to_json
	end

	post '/api/:sport/record', :auth => :user do
		record_json = JSON.parse(request.body.read);

		record_holders = []
		record_json["record_holders"].each {|record_holder|
			user = User.find_by_name(record_holder["name"]["name"]);

			record_holders.push(RecordHolder.new({user:user, year:record_holder['year']}));
		}

		record = FantasyRecord.new({
			type: record_json['type'],
			record: record_json["record"],
			value: record_json["value"],
			sport: params[:sport],
			record_holders: record_holders,
			confirmed: false,
			submitted_by: @user,
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