require 'mongo_mapper'

class Rating
	include MongoMapper::Document

	key :rating, Integer, :required => true

	belongs_to :user
	belongs_to :team_name
end
