require 'mongo_mapper'

class Season
	include MongoMapper::Document

	key :year, Integer
	key :sport, String
	key :league_name, String
	key :championship_score, String

	many :results
end
