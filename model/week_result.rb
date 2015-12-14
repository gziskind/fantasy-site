require 'mongo_mapper'

class WeekResult
	include MongoMapper::Document

	key :week, Integer

	belongs_to :season
	many :matchups
end
