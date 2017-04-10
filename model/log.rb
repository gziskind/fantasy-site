require 'mongo_mapper'

class Log
    include MongoMapper::Document

    key :logger, String
    key :level, String
    key :log_message, String
    key :time, Time

end