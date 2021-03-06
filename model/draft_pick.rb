require 'mongo_mapper'

class DraftPick
    include MongoMapper::Document

    key :position, String
    key :cost, Integer
    key :pick, Integer
    key :year, Integer
    key :sport, String
    key :keeper, Boolean

    belongs_to :user
    belongs_to :player
end
