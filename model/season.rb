require 'mongo_mapper'

class Season
	include MongoMapper::Document

	key :year, Integer
	key :sport, String
	key :league_name, String

	many :results
end
