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
require_relative 'model/event'
require_relative 'model/podcast'
require_relative 'model/roto_stat'
require_relative 'model/week_result'
require_relative 'model/team_result'
require_relative 'model/matchup'
require_relative 'model/player'
require_relative 'model/draft_pick'

def connect(database, host = 'localhost', port = 27017, user = nil, password = nil)
	MongoMapper.connection = Mongo::Connection.new(host, port)
	MongoMapper.database = database
	MongoMapper.database.authenticate(user, password) if user && password
end

def test_connect
	connect 'test_database'
end

def production_connect
	connect 'aepifantasy'
end

def insert_points(year, points)
	season = Season.find_by_sport_and_year('football', year)

	season.results.sort_by! {|result|
		result.place
	}

	season.results.each_with_index {|result,index|
		result.points = points[index]
		result.save!
	}
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

def create_weekly_result
	season = Season.new(year: 2016, sport: 'football', league_name: 'Test')
	user1 = User.all[0]
	user2 = User.all[1]

	result1 = TeamResult.new({points: 150, user: user1})
	result2 = TeamResult.new({points:75, user: user2})
	matchup = Matchup.new({team1: result1, team2: result2})
	week_result = WeekResult.new({week:1, matchups: [matchup]})

	season.week_results.push(week_result);

	season.save
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
