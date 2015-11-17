require 'mongo_mapper'

class TeamResult
	include MongoMapper::Document

	key :points, Float

	belongs_to :matchup
	belongs_to :user
end
