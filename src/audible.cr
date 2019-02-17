require "http/client"
require "json"
require "readline"
require "uri"
require "xml"
require "./audible/*"

module Audible
  AMAZON_LOGIN = URI.parse("https://www.amazon.com")
  AMAZON_API   = URI.parse("https://api.amazon.com")
  AUDIBLE_API  = URI.parse("https://api.audible.com")

  private def self.add_request_headers(response, headers)
    new_cookies = HTTP::Cookies.from_headers(response.headers)

    cookies = HTTP::Cookies.from_headers(headers)
    new_cookies.each do |cookie|
      if cookies[cookie.name]?
        if cookie.value != %("")
          cookies[cookie.name] = cookie.value
        end
      else
        cookies[cookie.name] = cookie.value
      end
    end

    headers = cookies.add_request_headers(headers)
    headers
  end

  def self.login(email, password)
    client = HTTP::Client.new(AMAZON_LOGIN)
    headers = HTTP::Headers.new

    headers["Accept"] = "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8"
    headers["Accept-Charset"] = "utf-8"
    headers["Accept-Language"] = "en-US"
    headers["Host"] = "www.amazon.com"
    headers["Origin"] = "https://www.amazon.com"
    headers["User-Agent"] = "Mozilla/5.0 (iPhone; CPU iPhone OS 10_3_1 like Mac OS X) AppleWebKit/603.1.30 (KHTML, like Gecko) Mobile/14E304"

    oauth_url = "/ap/signin?openid.oa2.response_type=token&openid.return_to=https://www.amazon.com/ap/maplanding&openid.assoc_handle=amzn_audible_ios_us&openid.identity=http://specs.openid.net/auth/2.0/identifier_select&pageId=amzn_audible_ios&accountStatusPolicy=P1&openid.claimed_id=http://specs.openid.net/auth/2.0/identifier_select&openid.mode=checkid_setup&openid.ns.oa2=http://www.amazon.com/ap/ext/oauth/2&openid.oa2.client_id=device:6a52316c62706d53427a5735505a76477a45375959566674327959465a6374424a53497069546d45234132435a4a5a474c4b324a4a564d&language=en_US&openid.ns.pape=http://specs.openid.net/extensions/pape/1.0&marketPlaceId=AF2M0KC94RCEA&openid.oa2.scope=device_auth_access&forceMobileLayout=true&openid.ns=http://specs.openid.net/auth/2.0&openid.pape.max_auth_age=0"

    until headers["Cookie"]?.try &.includes? "session-token"
      response = client.get("/", headers)
      headers = add_request_headers(response, headers)
    end

    response = client.get(oauth_url, headers)
    headers = add_request_headers(response, headers)

    inputs = {} of String => String

    body = XML.parse_html(response.body)
    body.xpath_nodes(%q(.//input[@type="hidden"])).each do |node|
      if node["name"]? && node["value"]?
        inputs[node["name"]] = node["value"]
      end
    end

    signin_url = "/ap/signin"

    inputs["email"] = email
    inputs["password"] = password
    inputs["metadata1"] = encrypt_metadata(%({"start":#{Time.now.to_unix_ms}}))

    raw_params = {} of String => Array(String)
    inputs.each { |key, value| raw_params[key] = [value] }

    body = HTTP::Params.new(raw_params).to_s

    headers["Referer"] = "https://www.amazon.com#{oauth_url}"
    headers["Content-Type"] = "application/x-www-form-urlencoded"

    response = client.post(signin_url, headers, body: body)
    headers = add_request_headers(response, headers)

    body = XML.parse_html(response.body)
    inputs = {} of String => String

    body.xpath_nodes(%q(.//input[@type="hidden"])).each do |node|
      if node["name"]? && node["value"]?
        inputs[node["name"]] = node["value"]
      end
    end

    captcha = body.xpath_node(%q(//img[@alt="Visual CAPTCHA image, continue down for an audio option."]))
    puts captcha.not_nil!["src"]

    guess = Readline.readline("Answer for CAPTCHA: ")
    guess = guess.not_nil!.strip.downcase

    inputs["guess"] = guess
    inputs["use_image_captcha"] = "true"
    inputs["use_audio_captcha"] = "false"
    inputs["showPasswordChecked"] = "false"
    inputs["email"] = email
    inputs["password"] = password

    raw_params = {} of String => Array(String)
    inputs.each { |key, value| raw_params[key] = [value] }

    body = HTTP::Params.new(raw_params).to_s

    response = client.post(signin_url, headers, body: body)
    headers = add_request_headers(response, headers)

    if response.status_code == 302
      map_landing = HTTP::Params.parse(URI.parse(response.headers["Location"]).query.not_nil!)

      login_object = {
        "aToken"       => map_landing["aToken"],
        "access_token" => map_landing["openid.oa2.access_token"],
        "cookies"      => {} of String => String,
      }

      HTTP::Cookies.from_headers(headers).each do |cookie|
        login_object["cookies"].as(Hash)[cookie.name] = cookie.value
      end

      return login_object
    else
      raise "Unable to login."
    end
  end

  def self.auth_register(login_object)
    body = JSON.build do |json|
      json.object do
        json.field "requested_token_type", ["bearer", "mac_dms", "website_cookies"]

        json.field "cookies" do
          json.object do
            json.field "website_cookies" do
              json.array do
                login_object["cookies"].as(Hash).each do |key, value|
                  json.object do
                    json.field "Name", key
                    json.field "Value", value
                  end
                end
              end
            end

            json.field "domain", ".amazon.com"
          end
        end

        json.field "registration_data" do
          json.object do
            json.field "domain", "Device"
            json.field "app_version", "3.1.2"
            json.field "device_serial", "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
            json.field "device_type", "A2CZJZGLK2JJVM"
            json.field "device_name", "%FIRST_NAME%%FIRST_NAME_POSSESSIVE_STRING%%DUPE_STRATEGY_1ST%Audible for iPhone"
            json.field "os_version", "10.3.1"
            json.field "device_model", "iPhone"
            json.field "app_name", "Audible"
          end
        end

        json.field "auth_data" do
          json.object do
            json.field "access_token", login_object["access_token"]
          end
        end

        json.field "requested_extensions", ["device_info", "customer_info"]
      end
    end

    client = HTTP::Client.new(AMAZON_API)
    headers = HTTP::Headers.new
    headers["Host"] = "api.amazon.com"
    headers["Content-Type"] = "application/json"
    headers["Accept-Charset"] = "utf-8"
    headers["x-amzn-identity-auth-domain"] = "api.amazon.com"
    headers["Accept"] = "application/json"
    headers["User-Agent"] = "AmazonWebView/Audible/3.1.2/iOS/10.3.1/iPhone"
    headers["Accept-Language"] = "en_US"
    headers["Cookie"] = login_object["cookies"].as(Hash).map { |key, value| "#{key}=#{value}" }.join("; ")

    return JSON.parse(client.post("/auth/register", headers, body: body).body)
  end

  def self.refresh_token(refresh_token)
    client = HTTP::Client.new(AMAZON_API)

    body = {
      "app_name"             => "Audible",
      "app_version"          => "3.1.2",
      "source_token"         => refresh_token,
      "requested_token_type" => "access_token",
      "source_token_type"    => "refresh_token",
    }

    headers = HTTP::Headers.new
    headers["Content-Type"] = "application/x-www-form-urlencoded"
    headers["x-amzn-identity-auth-domain"] = "api.amazon.com"

    return JSON.parse(client.post("/auth/token", headers, form: body).body)
  end

  def self.user_profile(access_token)
    client = HTTP::Client.new(AMAZON_API)
    return JSON.parse(client.get("/user/profile?access_token=#{access_token}").body)
  end
end
