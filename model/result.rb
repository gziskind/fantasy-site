require 'mongo_mapper'

class Result
	include MongoMapper::EmbeddedDocument

	key :wins, Integer
	key :loses, Integer

	belongs_to :user
	belongs_to :season
end