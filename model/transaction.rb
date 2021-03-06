require 'mongo_mapper'

class Transaction
    include MongoMapper::Document

    key :type, String
    key :bid, Integer
    key :date, Date

    belongs_to :user
    belongs_to :player

end
