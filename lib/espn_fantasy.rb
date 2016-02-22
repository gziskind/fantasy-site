module EspnFantasy

  LOGIN_URI = "https://registerdisney.go.com/jgc/v2/client/ESPN-ESPNCOM-PROD/guest/login?langPref=en-US"

  def self.get_page(espn_url, user, password)

    body = {
      loginValue: user,
      password: password
    }.to_json

    login_response = HTTParty.post(LOGIN_URI, body: body, headers: {'Content-type'=>'application/json'});

    login_swid = login_response['data']['token']['swid']
    cookie_string = "SWID=#{login_swid}; espnAuth={\"swid\":\"#{login_swid}\"};" 

    response = HTTParty.get(espn_url, :headers => {"Cookie" => cookie_string});

    return response.body
  end
end

