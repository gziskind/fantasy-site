require 'mongo_mapper'

class TeamResult
	include MongoMapper::Document

	key :points, Integer

	belongs_to :matchup
	belongs_to :user
end
