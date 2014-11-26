require_relative 'model/user'
require_relative 'model/role'
require_relative 'model/team_name'
require_relative 'model/hall_of_names'
require_relative 'model/fantasy_fact'
require_relative 'model/fantasy_record'
require_relative 'model/season'
require_relative 'model/result'
require_relative 'model/baseball_result'
require_relative 'model/football_result'
require_relative 'model/poll'
require_relative 'model/question'
require_relative 'model/response'
require_relative 'model/answer'
require_relative 'model/rating'

def connect(database)
	MongoMapper.connection = Mongo::Connection.new('localhost')
	MongoMapper.database = database
end

def test_connect
	connect 'test_database'
end

def production_connect
	connect 'aepifantasy'
end

def create_roles
	roles = ['admin','baseball_commish','football_commish','football','baseball'];

	roles.each {|role_name|
		role = Role.new({name:role_name})
		role.save!
		puts "Created role #{role_name}"
	}
end

def create_user(username, password, name, unique_name, roles)
	require 'digest/md5'

	role_objects = []
	roles.each {|role| 
		role_objects.push(Role.find_by_name role);
	}

	password_digest = Digest::MD5.hexdigest(password);
	user = User.new({username: username, password: password_digest, name: name, unique_name: unique_name, roles: role_objects});
	user.save!
end

def create_season(year, sport)
	if sport == 'baseball'
		result_class = BaseballResult
	else
		result_class = FootballResult
	end

	user1 = User.find_by_username("Greg");
	user2 = User.find_by_username("Greg2");
	user3 = User.find_by_username("Greg3");
	user4 = User.find_by_username("Greg4");
	user5 = User.find_by_username("Greg5");

	results = []
	results.push(result_class.new({team_name:"Team 1", wins: 80, losses:25, ties:12, points: 1300, place:5, user:user1}))
	results.push(result_class.new({team_name:"Team 2", wins: 81, losses:24, ties:12, points: 1301, place:3, user:user2}))
	results.push(result_class.new({team_name:"Team 3", wins: 82, losses:23, ties:12, points: 1302, place:2, user:user3}))
	results.push(result_class.new({team_name:"Team 4", wins: 83, losses:22, ties:12, points: 1303, place:1, user:user4}))
	results.push(result_class.new({team_name:"Team 5", wins: 84, losses:21, ties:12, points: 1304, place:4, user:user5}))

	season = Season.new({year:year, sport: sport, league_name: 'League Name', championship_score: '7-4-1', results: results});

	season.save!
end
