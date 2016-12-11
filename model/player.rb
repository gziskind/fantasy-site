require 'mongo_mapper'

class Player
    include MongoMapper::Document

    key :first_name, String
    key :last_name, String
    key :sport, String

    many :draft_picks
end
