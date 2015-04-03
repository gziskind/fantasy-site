require 'mongo_mapper'

class Podcast
	include MongoMapper::Document

	key :name, String
	key :url, String

	many :users

	timestamps!

end