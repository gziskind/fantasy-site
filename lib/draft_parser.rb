require 'json'

module DraftParser

  POSITIONS = ["C","1B","2B","SS","3B","OF","SP","RP","DH"]

  def self.get_baseball_draft_data(file)
    name_map = JSON.parse(File.read("user_map.json"))
    pick_num = 1
    draft_data =[]

    File.open(file).each {|line|
      match_data = line.match(/(\w+)\s-\s([A-Za-z. \-']+)[ ]([(]K\d?[)])?[ ]?(\w+)/)

      if(!match_data.nil?)
        team = match_data[1]
        name = match_data[2]
        keeper = !match_data[3].nil? 
        position = match_data[4].upcase

        if POSITIONS.include? position

          draft_data.push({
            name: name.strip,
            position: position,
            pick: pick_num,
            user: name_map[team],
            keeper: false
          })
        else
          puts "Position invalid [#{name}] [#{position}]"
        end

        pick_num += 1
      end
    }

    return draft_data
  end
end