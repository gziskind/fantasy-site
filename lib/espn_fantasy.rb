require 'net/http'
require 'httparty'
require 'nokogiri'

module EspnFantasy

  LOGIN_URI = "https://registerdisney.go.com/jgc/v2/client/ESPN-ESPNCOM-PROD/guest/login?langPref=en-US"

  def self.get_page(espn_url, user, password)

    body = {
      loginValue: user,
      password: password
    }.to_json

    login_response = HTTParty.post(LOGIN_URI, body: body, headers: {'Content-type'=>'application/json'});

    login_swid = login_response['data']['token']['swid']
    s2_value = login_response['data']['s2']
    cookie_string = "SWID=#{login_swid}; espnAuth={\"swid\":\"#{login_swid}\"}; espn_s2=#{s2_value}; utag_main=test" 

    response = HTTParty.get(espn_url, :headers => {"Cookie" => cookie_string});

    return response.body
  end

  def self.get_baseball_draft_url(leagueId, year)
    return "http://games.espn.go.com/flb/tools/draftrecap?leagueId=#{leagueId}&seasonId=#{year}"
  end

  def self.get_football_draft_url(leagueId, year)
    return "http://games.espn.go.com/ffl/tools/draftrecap?leagueId=#{leagueId}&seasonId=#{year}"
  end

  def self.get_baseball_draft_data(user, password, leagueId, year)
    url = get_baseball_draft_url(leagueId, year)

    response_body = get_page(url, user, password)

    return parse_draft_data(response_body)
  end

  def self.get_football_draft_data(user, password, leagueId, year)
    url = get_football_draft_url(leagueId, year)

    response_body = get_page(url, user, password)

    return parse_draft_data(response_body)
  end

  def self.parse_draft_data(page)
    html = Nokogiri::HTML(page);

    return extract_draft_data(html)
  end

  def self.extract_draft_data(html)
    draft_type = get_draft_type(html)
    if(draft_type == :auction)
      puts "Parsing Auction Draft"
      extract_auction_data(html)
    elsif(draft_type == :snake)
      puts "Parsing Snake Draft"
      extract_snake_data(html)
    else
      puts "Could not determine draft type"
    end
  end


  def self.get_draft_type(html) 
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

  def self.extract_snake_data(html) 
    picks = html.css "//table/tr[@class='tableBody']"
    draft_data = []

    for index in 0..(picks.size - 1)
      pick_data = get_pick_data(picks[index])
      draft_data.push(pick_data)
    end

    return draft_data
  end

  def self.extract_auction_data(html) 
    teams = html.css "//table"
    draft_data = []

    for index in 2..(teams.size - 1)
      get_draft_data_team(draft_data, teams[index])
    end
    
    return draft_data
  end

  def self.get_pick_data(pick)
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

  def self.extract_user(a)
    team_and_user = a.attribute("title").content
    match_data = team_and_user.match(/.*\((.*, )?(.*)\)/)
    match_data[2]
  end

  def self.parse_player(player)
    match_data = player.match(/(.*)[,]\s\w*.(\w*).*(\w?)/);

    return match_data[1].chomp("*"), match_data[2]
  end

  def self.get_draft_data_team(draft_data, team)
    user_data = team.css "/tr[1]/td/a"
    user = extract_user user_data

    picks = team.css "tr[@class='tableBody']"
    picks.each {|pick|
      data = extract_pick_data pick
      data[:user] = user
      draft_data.push(data)
    }
  end

  def self.extract_pick_data(pick)
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

  def self.is_keeper(pick)
    keeper = pick.css('/td[2]/span')[0]
    if(keeper && keeper.content == 'K')
      return true
    else
      return false
    end
  end
end

