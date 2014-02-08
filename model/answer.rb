require 'mongo_mapper'

class Answer
	include MongoMapper::Document

	key :answer, String

	belongs_to :response
	belongs_to :question
end