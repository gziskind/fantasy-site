require 'mongo_mapper'

class Response
	include MongoMapper::Document

	key :time, Time

	belongs_to :poll
	belongs_to :user
	many :answers
end