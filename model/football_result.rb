require 'mongo_mapper'

class FootballResult < Result
	key :points, Float

	def record 
		return "#{self.wins} - #{self.losses} - #{self.ties} (#{self.points} pts)"
	end
end