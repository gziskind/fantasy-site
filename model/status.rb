require 'mongo_mapper'

class Status
    include MongoMapper::Document

    key :service, String
    key :last_updated, Time

    def self.update_service(service)
        status = Status.find_by_service(service)
        if(status)
            status.last_updated = Time.now
            status.save!
        else
            status = Status.new({
                service: service,
                last_updated: Time.now
            })
            status.save!
        end
    end
end