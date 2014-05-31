require 'mongo_mapper'

class FootballResult < Result
	key :points, Float

	def record 
		return "#{self.wins} - #{self.losses} (#{self.points} pts)"
	end
end