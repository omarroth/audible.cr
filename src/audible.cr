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
    inputs["metadata1"] = encrypt_metadata(%({"start":#{Time.now.to_unix_ms},"interaction":{"keys":0,"keyPressTimeIntervals":[],"copies":0,"cuts":0,"pastes":0,"clicks":0,"touches":0,"mouseClickPositions":[],"keyCycles":[],"mouseCycles":[],"touchCycles":[]},"version":"3.0.0","lsUbid":"X39-6721012-8795219:1549849158","timeZone":-6,"scripts":{"dynamicUrls":["https://images-na.ssl-images-amazon.com/images/I/61HHaoAEflL._RC|11-BZEJ8lnL.js,01qkmZhGmAL.js,71qOHv6nKaL.js_.js?AUIClients/AudibleiOSMobileWhiteAuthSkin#mobile","https://images-na.ssl-images-amazon.com/images/I/21T7I7qVEeL._RC|21T1XtqIBZL.js,21WEJWRAQlL.js,31DwnWh8lFL.js,21VKEfzET-L.js,01fHQhWQYWL.js,51TfwrUQAQL.js_.js?AUIClients/AuthenticationPortalAssets#mobile","https://images-na.ssl-images-amazon.com/images/I/0173Lf6yxEL.js?AUIClients/AuthenticationPortalInlineAssets","https://images-na.ssl-images-amazon.com/images/I/211S6hvLW6L.js?AUIClients/CVFAssets","https://images-na.ssl-images-amazon.com/images/G/01/x-locale/common/login/fwcim._CB454428048_.js"],"inlineHashes":[-1746719145,1334687281,-314038750,1184642547,-137736901,318224283,585973559,1103694443,11288800,-1611905557,1800521327,-1171760960,-898892073],"elapsed":52,"dynamicUrlCount":5,"inlineHashesCount":13},"plugins":"unknown||320-568-548-32-*-*-*","dupedPlugins":"unknown||320-568-548-32-*-*-*","screenInfo":"320-568-548-32-*-*-*","capabilities":{"js":{"audio":true,"geolocation":true,"localStorage":"supported","touch":true,"video":true,"webWorker":true},"css":{"textShadow":true,"textStroke":true,"boxShadow":true,"borderRadius":true,"borderImage":true,"opacity":true,"transform":true,"transition":true},"elapsed":1},"referrer":"","userAgent":"#{headers["User-Agent"]}","location":"https://www.amazon.com#{oauth_url}","webDriver":null,"history":{"length":1},"gpu":{"vendor":"Apple Inc.","model":"Apple A9 GPU","extensions":[]},"math":{"tan":"-1.4214488238747243","sin":"0.8178819121159085","cos":"-0.5753861119575491"},"performance":{"timing":{"navigationStart":#{Time.now.to_unix_ms},"unloadEventStart":0,"unloadEventEnd":0,"redirectStart":0,"redirectEnd":0,"fetchStart":#{Time.now.to_unix_ms},"domainLookupStart":#{Time.now.to_unix_ms},"domainLookupEnd":#{Time.now.to_unix_ms},"connectStart":#{Time.now.to_unix_ms},"connectEnd":#{Time.now.to_unix_ms},"secureConnectionStart":#{Time.now.to_unix_ms},"requestStart":#{Time.now.to_unix_ms},"responseStart":#{Time.now.to_unix_ms},"responseEnd":#{Time.now.to_unix_ms},"domLoading":#{Time.now.to_unix_ms},"domInteractive":#{Time.now.to_unix_ms},"domContentLoadedEventStart":#{Time.now.to_unix_ms},"domContentLoadedEventEnd":#{Time.now.to_unix_ms},"domComplete":#{Time.now.to_unix_ms},"loadEventStart":#{Time.now.to_unix_ms},"loadEventEnd":#{Time.now.to_unix_ms}}},"end":#{Time.now.to_unix_ms},"timeToSubmit":108873,"form":{"email":{"keys":0,"keyPressTimeIntervals":[],"copies":0,"cuts":0,"pastes":0,"clicks":0,"touches":0,"mouseClickPositions":[],"keyCycles":[],"mouseCycles":[],"touchCycles":[],"width":290,"height":43,"checksum":"C860E86B","time":12773,"autocomplete":false,"prefilled":false},"password":{"keys":0,"keyPressTimeIntervals":[],"copies":0,"cuts":0,"pastes":0,"clicks":0,"touches":0,"mouseClickPositions":[],"keyCycles":[],"mouseCycles":[],"touchCycles":[],"width":290,"height":43,"time":10353,"autocomplete":false,"prefilled":false}},"canvas":{"hash":-373378155,"emailHash":-1447130560,"histogramBins":[]},"token":null,"errors":[],"metrics":[{"n":"fwcim-mercury-collector","t":0},{"n":"fwcim-instant-collector","t":0},{"n":"fwcim-element-telemetry-collector","t":2},{"n":"fwcim-script-version-collector","t":0},{"n":"fwcim-local-storage-identifier-collector","t":0},{"n":"fwcim-timezone-collector","t":0},{"n":"fwcim-script-collector","t":1},{"n":"fwcim-plugin-collector","t":0},{"n":"fwcim-capability-collector","t":1},{"n":"fwcim-browser-collector","t":0},{"n":"fwcim-history-collector","t":0},{"n":"fwcim-gpu-collector","t":1},{"n":"fwcim-battery-collector","t":0},{"n":"fwcim-dnt-collector","t":0},{"n":"fwcim-math-fingerprint-collector","t":0},{"n":"fwcim-performance-collector","t":0},{"n":"fwcim-timer-collector","t":0},{"n":"fwcim-time-to-submit-collector","t":0},{"n":"fwcim-form-input-telemetry-collector","t":4},{"n":"fwcim-canvas-collector","t":2},{"n":"fwcim-captcha-telemetry-collector","t":0},{"n":"fwcim-proof-of-work-collector","t":1},{"n":"fwcim-ubf-collector","t":0},{"n":"fwcim-timer-collector","t":0}]}))

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
