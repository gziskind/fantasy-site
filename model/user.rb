require 'mongo_mapper'

class User
	include MongoMapper::Document

	key :username, String, :required => true
	key :password, String

	belongs_to :role
	many :team_names
end
