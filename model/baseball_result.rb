require 'mongo_mapper'

class BaseballResult < Result
	key :ties, Integer

	def record
		return "#{self.wins} - #{self.losses} - #{self.ties}"
	end
end