require 'mongo_mapper'

class Poll
	include MongoMapper::Document

	key :sport, String
	key :title, String

	many :questions
	many :responses
end