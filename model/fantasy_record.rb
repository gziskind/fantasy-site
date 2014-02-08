require 'mongo_mapper'

class FantasyRecord
	include MongoMapper::Document

	key :record, String
	key :sport, String
	key :season, String

	many :disputes
	belongs_to :submitted_by, :class_name => 'User'
end
