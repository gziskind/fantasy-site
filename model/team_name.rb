require 'mongo_mapper'

class TeamName
	include MongoMapper::Document

	key :name, String, :required => true
	key :sport, String, :required => true
	key :likes_ids, Array
	key :dislikes_ids, Array

	belongs_to :owner, :class_name => 'User'
	belongs_to :hall_of_names
	many :likes, :class_name => 'User', :in => :likes_ids
	many :dislikes, :class_name => 'User', :in => :dislikes_ids
end