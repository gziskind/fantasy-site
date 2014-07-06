require 'mongo_mapper'

class FantasyRecord
	include MongoMapper::Document

	key :type, String
	key :record, String
	key :value, String
	key :years, Array
	key :sport, String
	key :owner_ids, Array
	key :confirmed, Boolean

	many :owners, :in => :owner_ids, :class_name => 'User'

	belongs_to :submitted_by, :class_name => 'User'
end
