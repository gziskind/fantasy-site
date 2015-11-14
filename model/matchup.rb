require 'mongo_mapper'

class Matchup
	include MongoMapper::Document

	belongs_to :week_result

	many :team_results
end
