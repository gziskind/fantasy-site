require 'mongo_mapper'

class FantasyRecord
	include MongoMapper::Document

	key :record, String
	key :value, String
	key :sport, String
	key :season, String
	key :team_name, String

	many :disputes
	belongs_to :submitted_by, :class_name => 'User'
	belongs_to :owner, :class_name => 'User'
end
