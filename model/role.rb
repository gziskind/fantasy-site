require 'mongo_mapper'

class Role
	include MongoMapper::Document

	key :name, String

	many :users
end