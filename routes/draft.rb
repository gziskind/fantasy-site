class FantasyServer 

    # Views
    get '/:sport/draft' do
        event "#{params[:sport].capitalize}DraftResults"
        @sport = params[:sport];
        @header_index = @sport;

        @seasons = DraftPick.where(sport: params[:sport]).distinct(:year)

        @seasons.sort!.reverse!

        erb :draftResults
    end

    # API Calls
    get '/api/:sport/draft/:year' do
        picks = DraftPick.find_all_by_sport_and_year(params[:sport],params[:year].to_i)

        pick_data = picks.map {|pick|
            data = {
                player: "#{pick.player.first_name} #{pick.player.last_name}",
                pick: pick.pick,
                position: pick.position,
                keeper: pick.keeper,
                user: pick.user.name
            }

            data[:cost] = pick.cost if !pick.cost.nil?

            data
        }

        pick_data.to_json
    end
end

