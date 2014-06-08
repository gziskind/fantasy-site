require 'mongo_mapper'

class User
	include MongoMapper::Document

	key :username, String, :required => true
	key :password, String
	key :name, String
	key :role_ids, Array

	many :roles, :in => :role_ids
	many :team_names

	def public_user
		{
			username: username,
			id: id,
			name: name,
			roles: roles
		}
	end
end
