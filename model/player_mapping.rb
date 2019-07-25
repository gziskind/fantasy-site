require 'mongo_mapper'

class PlayerMapping
    include MongoMapper::Document

    key :twitter_name, String
    key :espn_name, String
end
