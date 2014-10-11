require 'mongo_mapper'

class BaseballResult < Result
	def record
		return "#{self.wins} - #{self.losses} - #{self.ties}"
	end
end