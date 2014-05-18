require 'mongo_mapper'

class User
	include MongoMapper::Document

	key :username, String, :required => true
	key :password, String

	belongs_to :role
	many :team_names

	def public_user
		{
			username: username,
			id: id
		}.to_json
	end
end
