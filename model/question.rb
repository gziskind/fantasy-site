require 'mongo_mapper'

class Question
	include MongoMapper::Document

	key :type, String
	key :question, String
	key :options, Array

	belongs_to :poll
	many :answers
end