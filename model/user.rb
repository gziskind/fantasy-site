require 'mongo_mapper'

class User
	include MongoMapper::Document

	key :username, String, :required => true
	key :password, String
	key :unique_name, String
	key :name, String
	key :role_ids, Array
	key :image_url, String
	key :bio, String
	key :slack_id, String
	key :telegram_id, String

	key :notification_homeruns_team, Boolean
	key :notification_homeruns_opponent, Boolean
	key :notification_steals_team, Boolean
	key :notification_steals_opponent, Boolean

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
