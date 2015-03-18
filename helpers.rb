module Helpers
	def is_baseball_active
		if @header_index == 'baseball'
			return 'active'
		else
			return ''
		end
	end

	def is_football_active 
		if @header_index == 'football'
			return 'active'
		else
			return ''
		end
	end

	def is_admin_active
		if @header_index == 'admin'
			return 'active'
		else
			return ''
		end
	end

	def is_profiles_active
		if @header_index == 'profiles'
			return 'active'
		else
			return ''
		end
	end

	def current_year(sport)
		seasons = Season.find_all_by_sport(sport);
		seasons = seasons.map {|season|
			season.year
		}

		seasons.sort!.reverse!
		seasons[0]
	end

	def is_user?
		@user != nil
	end

	def is_admin?
		admin = false
		@user.roles.each {|role|
			if role.name == "admin"
				admin = true
			end
		} if @user != nil

		admin
	end

	def event(event_name, user = 'Anonymous')
		user = @user.username if @user != nil

		ev = Event.new({username: user, event: event_name, time: Time.now});
		ev.save!
	end
end