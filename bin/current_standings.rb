#! /usr/bin/env ruby

require 'net/http'
require 'httparty'
require 'nokogiri'

def query_espn
	hostname = "r.espn.go.com"
	uri = "https://#{hostname}/espn/memberservices/pc/login"

	options = {
		"username" => "gziskind",
		"password" => "kaplacko",
		"SUBMIT" => 1
	}

	cookie_header = nil

	request = Net::HTTP::Post.new(uri)
	request.form_data = options
	Net::HTTP::start(hostname, 443, :use_ssl => true) { |http|
		http.use_ssl = true
		http.verify_mode = OpenSSL::SSL::VERIFY_NONE # read into this
		response = http.request(request);

		cookie_header = response['set-cookie']
	}

	hostname = "games.espn.go.com"
	uri = "http://#{hostname}/flb/standings?leagueId=33843&seasonId=2014"
	response = HTTParty.get(uri, :headers => {"Cookie" => cookie_header});

	return response.body
end

def extract_team_info(html)
	teams = html.css "//table[@class='tableBody'][1]/tr/td/a"

	team_info = []
	teams.each {|team|
		match_data  = team['title'].match(/.*\((.*)\)/)
		team_info.push({
			team_name: team.content,
			owner: match_data[1]
		})
	}

	wins = html.css "//table[@class='tableBody'][1]/tr/td[2]"
	wins.each_with_index {|win,index|
		if index > 0
			team_info[index-1][:wins] = win.content
		end
	}

	losses = html.css "//table[@class='tableBody'][1]/tr/td[3]"
	losses.each_with_index {|loss,index|
		if index > 0
			team_info[index-1][:losses] = loss.content
		end
	}

	ties = html.css "//table[@class='tableBody'][1]/tr/td[4]"
	ties.each_with_index {|tie,index|
		if index > 0
			team_info[index-1][:ties] = tie.content
		end
	}

	return team_info
end

response_body = query_espn
html = Nokogiri::HTML(response_body)
info = extract_team_info html
puts info
