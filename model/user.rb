require 'mongo_mapper'

class User
	include MongoMapper::Document

	key :username, String, :required => true
	key :password, String
	key :unique_name, String
	key :name, String
	key :role_ids, Array
	key :image_url, String

	many :roles, :in => :role_ids
	many :team_names

	def public_user
		{
			username: username,
			id: id,
			name: name,
			uniqueName: unique_name,
			roles: roles
		}
	end
end
