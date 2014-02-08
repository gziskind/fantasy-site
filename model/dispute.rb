require 'mongo_mapper'

class Dispute
	include MongoMapper::EmbeddedDocument

	key :reason, String

	belongs_to :user
end