require 'mongo_mapper'

class TeamName
	include MongoMapper::Document

	key :name, String, :required => true
	key :sport, String, :required => true
	key :year, Integer
	key :total_rating, Float

	belongs_to :owner, :class_name => 'User'
	belongs_to :hall_of_names
	many :ratings

	timestamps!
end