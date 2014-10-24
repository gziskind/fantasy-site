require 'mongo_mapper'

class FantasyRecord
	include MongoMapper::Document

	key :type, String
	key :record, String
	key :value, String
	key :sport, String
	key :confirmed, Boolean

	many :record_holders

	belongs_to :submitted_by, :class_name => 'User'
end

class RecordHolder
	include MongoMapper::EmbeddedDocument

	key :year, String

	belongs_to :user
end
