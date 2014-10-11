require 'mongo_mapper'

class Result
	include MongoMapper::EmbeddedDocument

	key :team_name, String
	key :wins, Integer
	key :losses, Integer
	key :ties, Integer
	key :place, Integer

	belongs_to :user
	belongs_to :season
end