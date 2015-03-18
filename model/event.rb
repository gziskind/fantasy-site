require 'mongo_mapper'

class Event
	include MongoMapper::Document

	key :username, String
	key :event, String
	key :time, Time

end