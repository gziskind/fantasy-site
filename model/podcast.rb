require 'mongo_mapper'

class Podcast
	include MongoMapper::Document

	key :name, String
	key :path, String

	many :users

	timestamps!

end