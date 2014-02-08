require 'mongo_mapper'

class FantasyFact
	include MongoMapper::Document

	key :fact, String
	key :sport, String

	belongs_to :submitted_by, :class_name => 'User'
	many :disputes
end