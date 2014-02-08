require 'mongo_mapper'

class HallOfNames
	include MongoMapper::Document

	many :team_names
end