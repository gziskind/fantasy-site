require_relative 'model/user'
require_relative 'model/role'
require_relative 'model/team_name'
require_relative 'model/hall_of_names'
require_relative 'model/fantasy_fact'
require_relative 'model/dispute'
require_relative 'model/fantasy_record'
require_relative 'model/season'
require_relative 'model/result'
require_relative 'model/baseball_result'
require_relative 'model/football_result'
require_relative 'model/poll'
require_relative 'model/question'
require_relative 'model/response'
require_relative 'model/answer'

def test_connect
	MongoMapper.connection = Mongo::Connection.new('localhost')
	MongoMapper.database = 'test_database'
end