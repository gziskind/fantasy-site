require 'mongo_mapper'

class RotoStat
	include MongoMapper::Document

	key :name, String
	key :total_points, Float

	key :runs, String
	key :runs_points, Float
	key :homeruns, String
	key :homeruns_points, Float
	key :rbi, String
	key :rbi_points, Float
	key :sb, String
	key :sb_points, Float
	key :average, String
	key :average_points, Float
	key :ops, String
	key :ops_points, Float
	key :quality_starts, String
	key :quality_starts_points, Float
	key :innings, String
	key :innings_points, Float
	key :saves, String
	key :saves_points, Float
	key :era, String
	key :era_points, Float
	key :whip, String
	key :whip_points, Float
	key :k_per_9, String
	key :k_per_9_points, Float

	timestamps!
end
