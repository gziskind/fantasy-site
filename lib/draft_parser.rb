require 'json'
require 'net/http'
require 'httparty'
require 'nokogiri'
require 'date'
require_relative '../lib/espn_fantasy'

class DraftParser
  POSITIONS = ["C","1B","2B","SS","3B","OF","SP","RP","DH"]

  def initialize(cookie_string, year) 
    @cookie_string = cookie_string
    @year = year
  end

  def get_baseball_draft_data_from_file(file)
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
            keeper: keeper
          })
        else
          puts "Position invalid [#{name}] [#{position}]"
        end

        pick_num += 1
      end
    }

    return draft_data
  end

  def parse_football_draft(league_id)
    begin
      log_message "Parsing #{@year} Football Draft"

      response_body = EspnFantasy.get_football_draft_page(@year, league_id, @cookie_string);

      draft_data = parse_draft_data(response_body)

      if verify_draft_data(draft_data)
        save_draft_data(draft_data, 'football')
        log_message "Draft data for #{@year} saved"
      else
        log_message "Draft Data Invalid"
        log_message draft_data
      end
    rescue Exception => e
      log_message e, "ERROR"
    end
  end

  def parse_baseball_draft(league_id)
    begin
      log_message "Parsing #{@year} Baseball Draft"

      response_body = EspnFantasy.get_baseball_draft_page(@year, league_id, @cookie_string);

      draft_data = parse_draft_data(response_body)

      if verify_draft_data(draft_data)
        save_draft_data(draft_data, 'baseball')
        log_message "Draft data for #{@year} saved"
      else
        log_message "Draft Data Invalid"
        log_message draft_data
      end
    rescue Exception => e
      log_message e, "ERROR"
    end
  end

  private

   def log_message(message, level = "INFO")
    log = Log.new({
      logger: "DraftParser",
      level: level,
      log_message: message,
      time: Time.now
    });

    puts message
    log.save!
  end

  def parse_draft_data(page)
    html = Nokogiri::HTML(page);

    return extract_draft_data(html)
  end

  def extract_draft_data(html)
    draft_type = get_draft_type(html)
    if(draft_type == :auction)
      log_message "Parsing Auction Draft"
      extract_auction_data(html)
    elsif(draft_type == :snake)
      log_message "Parsing Snake Draft"
      extract_snake_data(html)
    else
      log_message "Could not determine draft type"
    end
  end

  def get_draft_type(html) 
    draft_info = html.css "//div[@class='games-alert-mod alert-mod2 games-grey-alert']"

    if(draft_info && draft_info.children.length >= 6)
      if(draft_info.children[5].content.include? "Auction")
        return :auction
      elsif(draft_info.children[5].content.include? "Snake")
        return :snake
      end
    end

    return nil
  end

  def extract_snake_data(html) 
    picks = html.css "//table/tr[@class='tableBody']"
    draft_data = []

    for index in 0..(picks.size - 1)
      pick_data = get_pick_data(picks[index])
      draft_data.push(pick_data)
    end

    return draft_data
  end

  def extract_auction_data(html) 
    teams = html.css "//table"
    draft_data = []

    for index in 2..(teams.size - 1)
      get_draft_data_team(draft_data, teams[index])
    end
    
    return draft_data
  end

  def get_pick_data(pick)
    pick_num = pick.css("/td[1]")[0].content
    player = pick.css("/td[2]")[0].content
    user_data = pick.css("/td[3]/a")
    user = extract_user(user_data)

    name, position = parse_player(player)
    
    {
      name: name,
      position: position,
      pick: pick_num,
      user: user,
      keeper: false
    }
  end

  def extract_user(a)
    team_and_user = a.attribute("title").content
    match_data = team_and_user.match(/.*\((.*, )?(.*)\)/)
    match_data[2]
  end

  def parse_player(player)
    match_data = player.match(/(.*)[,]\s\w*.(\w*).*(\w?)/);

    return match_data[1].chomp("*"), match_data[2]
  end

  def get_draft_data_team(draft_data, team)
    user_data = team.css "/tr[1]/td/a"
    user = extract_user user_data

    picks = team.css "tr[@class='tableBody']"
    picks.each {|pick|
      data = extract_pick_data pick
      data[:user] = user
      draft_data.push(data)
    }
  end

  def extract_pick_data(pick)
    dollar = pick.css("/td[3]")[0].content
    dollar[0] = ''
    player = pick.css("/td[2]")[0].content
    pick_num = pick.css("/td[1]")[0].content
    keeper = is_keeper(pick)

    name, position = parse_player(player)

    {
      name: name,
      position: position,
      amount: dollar,
      pick: pick_num,
      keeper: keeper
    }
  end

  def is_keeper(pick)
    keeper = pick.css('/td[2]/span')[0]
    if(keeper && keeper.content == 'K')
      return true
    else
      return false
    end
  end

  def verify_draft_data(draft_data)
    return !draft_data.nil?
  end

  def save_draft_data(draft_data, sport)
    draft_data.each {|draft_pick_data|
      user = User.find_by_unique_name(draft_pick_data[:user]);

      first_name, last_name = parse_player_name(draft_pick_data[:name])

      player = Player.find_by_first_name_and_last_name_and_sport(first_name, last_name, sport)
      if(player.nil?)
        player = Player.new({
          first_name: first_name,
          last_name: last_name,
          sport: sport
        })

        player.save!
      end

      pick_conf = {
        position: draft_pick_data[:position],
        pick: draft_pick_data[:pick],
        keeper: draft_pick_data[:keeper],
        year: @year,
        sport: sport,
        user: user,
        player: player
      };

      pick_conf[:cost] = draft_pick_data[:amount] if !draft_pick_data[:amount].nil?

      draft_pick = DraftPick.new(pick_conf)

      draft_pick.save!
    }
  end

  def parse_player_name(name)
    match_data = name.match(/([49A-Za-z.\-']+)\s(.+)/)

    return match_data[1], match_data[2]
  end

end

