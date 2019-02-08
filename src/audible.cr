require "uri"
require "http/client"
require "xml"

AMAZON_URL = URI.parse("https://www.amazon.com")

def login(email, password)
  client = HTTP::Client.new(AMAZON_URL)
  headers = HTTP::Headers.new

  headers["Host"] = "www.amazon.com"
  headers["Accept"] = "text/html,application/xhtml+xm…plication/xml;q=0.9,*/*;q=0.8"
  headers["User-Agent"] = "Mozilla/5.0 (X11; Linux x86_64; rv:64.0) Gecko/20100101 Firefox/64.0"
  headers["Accept-Language"] = "en-US"

  response = client.get("/", headers)
  headers = add_request_headers(response, headers)

  oauth_url = "/ap/signin?openid.return_to=https%3A%2F%2Fwww.amazon.com%2F%3F_encoding%3DUTF8%26opf_redir%3D1%26ref_%3Dnav_ya_signin&openid.identity=http%3A%2F%2Fspecs.openid.net%2Fauth%2F2.0%2Fidentifier_select&openid.assoc_handle=usflex&openid.mode=checkid_setup&openid.claimed_id=http%3A%2F%2Fspecs.openid.net%2Fauth%2F2.0%2Fidentifier_select&openid.ns=http%3A%2F%2Fspecs.openid.net%2Fauth%2F2.0&&openid.pape.max_auth_age=0"

  response = client.get(oauth_url, headers)
  headers = add_request_headers(response, headers)

  inputs = {} of String => String

  body = XML.parse_html(response.body)
  body.xpath_nodes(%q(.//input[@type="hidden"])).each do |node|
    if node["name"]? && node["value"]?
      inputs[node["name"]] = node["value"]
    end
  end
  # signin_url = body.xpath_node(%q(//form[@name="signIn"])).not_nil!["action"]
  signin_url = "/ap/signin"

  inputs["email"] = email
  inputs["password"] = password

  raw_params = {} of String => Array(String)
  inputs.each { |key, value| raw_params[key] = [value] }

  body = HTTP::Params.new(raw_params).to_s
  headers["Referer"] = oauth_url

  response = client.post(signin_url, headers, form: body)
  File.write("response.html", response.body)
  headers = add_request_headers(response, headers)
end

def add_request_headers(response, headers)
  new_cookies = HTTP::Cookies.from_headers(response.headers)

  cookies = HTTP::Cookies.from_headers(headers)
  new_cookies.each do |cookie|
    if cookies[cookie.name]?
      if cookie.value != %("")
        cookies[cookie.name] = cookie.value.strip('"')
      end
    else
      cookies[cookie.name] = cookie.value.strip('"')
    end
  end

  headers = cookies.add_request_headers(headers)
  headers
end
