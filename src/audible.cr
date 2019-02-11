require "uri"
require "http/client"
require "json"
require "xml"
require "./audible/*"

AMAZON_URL = URI.parse("https://www.amazon.com")
AMAZON_API = URI.parse("https://api.amazon.com")

module Audible
end

def login(email, password)
  client = HTTP::Client.new(AMAZON_URL)
  headers = HTTP::Headers.new

  headers["Accept"] = "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8"
  headers["Accept-Charset"] = "utf-8"
  headers["Accept-Language"] = "en-US"
  headers["Host"] = "www.amazon.com"
  headers["Origin"] = "https://www.amazon.com"
  headers["User-Agent"] = "Mozilla/5.0 (iPhone; CPU iPhone OS 10_3_1 like Mac OS X) AppleWebKit/603.1.30 (KHTML, like Gecko) Mobile/14E304"

  oauth_url = "/ap/signin?openid.return_to=https%3A%2F%2Fwww.amazon.com%2F%3Fref_%3Dnav_ya_signin&openid.identity=http%3A%2F%2Fspecs.openid.net%2Fauth%2F2.0%2Fidentifier_select&openid.assoc_handle=usflex&openid.mode=checkid_setup&openid.claimed_id=http%3A%2F%2Fspecs.openid.net%2Fauth%2F2.0%2Fidentifier_select&openid.ns=http%3A%2F%2Fspecs.openid.net%2Fauth%2F2.0&&openid.pape.max_auth_age=0"

  response = client.get("/", headers)
  headers = add_request_headers(response, headers)
  response = client.get(oauth_url, headers)
  headers = add_request_headers(response, headers)

  inputs = {} of String => String

  body = XML.parse_html(response.body)
  body.xpath_nodes(%q(.//input[@type="hidden"])).each do |node|
    if node["name"]? && node["value"]?
      inputs[node["name"]] = node["value"]
    end
  end

  signin_url = body.xpath_node(%q(//form[@name="signIn"])).not_nil!["action"]

  inputs["email"] = email
  inputs["password"] = password
  inputs["metadata1"] = encrypt_metadata(%({"start":#{Time.now.to_unix_ms},"interaction":{"keys":2,"keyPressTimeIntervals":[3061,6],"copies":0,"cuts":0,"pastes":0,"clicks":5,"touches":0,"mouseClickPositions":["744,188","736,179","690,223","376,233","813,286"],"keyCycles":[4,2],"mouseCycles":[59,47,92,78,39]},"version":"3.0.0","lsUbid":"X42-3760865-9592102:1549593713","timeZone":-6,"scripts":{"dynamicUrls":["https://images-na.ssl-images-amazon.com/images/G/01/AUIClients/ClientSideMetricsAUIJavascript@jserrorsForester.10f2559e93ec589d92509318a7e2acbac74c343a._V2_.js","https://images-na.ssl-images-amazon.com/images/I/61HHaoAEflL._RC|11-BZEJ8lnL.js,61q-U9rAZ3L.js,31x4ENTlVIL.js,31f4+QIEeqL.js,01N6xzIJxbL.js,518BI433aLL.js,01rpauTep4L.js,31QZSjMuoeL.js,61ofwvddDeL.js,01KsMxlPtzL.js_.js?AUIClients/AmazonUI","https://images-na.ssl-images-amazon.com/images/I/21T7I7qVEeL._RC|21T1XtqIBZL.js,21WEJWRAQlL.js,31DwnWh8lFL.js,21VKEfzET-L.js,01fHQhWQYWL.js,51Hqf9CH0tL.js_.js?AUIClients/AuthenticationPortalAssets","https://images-na.ssl-images-amazon.com/images/I/0173Lf6yxEL.js?AUIClients/AuthenticationPortalInlineAssets","https://images-na.ssl-images-amazon.com/images/I/21X0WwTcvbL.js?AUIClients/CVFAssets","https://images-na.ssl-images-amazon.com/images/G/01/x-locale/common/login/fwcim._CB457517591_.js"],"inlineHashes":[-1746719145,-1818136672,-314038750,-1809046278,2118203618,318224283,-1228118292,-1611905557,1800521327,-1171760960,-514826685],"elapsed":22,"dynamicUrlCount":6,"inlineHashesCount":11},"plugins":"Chrome PDF Plugin Chrome PDF Viewer Native Client ||1600-900-900-24-*-*-*","dupedPlugins":"Chrome PDF Plugin Chrome PDF Viewer Native Client ||1600-900-900-24-*-*-*","screenInfo":"1600-900-900-24-*-*-*","capabilities":{"js":{"audio":true,"geolocation":true,"localStorage":"supported","touch":false,"video":true,"webWorker":true},"css":{"textShadow":true,"textStroke":true,"boxShadow":true,"borderRadius":true,"borderImage":true,"opacity":true,"transform":true,"transition":true},"elapsed":0},"referrer":"https://www.amazon.com/","userAgent":"Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/72.0.3626.96 Safari/537.36","location":"https://www.amazon.com/ap/signin?openid.return_to=https%3A%2F%2Fwww.amazon.com%2F%3Fref_%3Dnav_ya_signin&openid.identity=http%3A%2F%2Fspecs.openid.net%2Fauth%2F2.0%2Fidentifier_select&openid.assoc_handle=usflex&openid.mode=checkid_setup&openid.claimed_id=http%3A%2F%2Fspecs.openid.net%2Fauth%2F2.0%2Fidentifier_select&openid.ns=http%3A%2F%2Fspecs.openid.net%2Fauth%2F2.0&&openid.pape.max_auth_age=0","webDriver":null,"history":{"length":3},"gpu":{"vendor":"X.Org","model":"AMD JUNIPER (DRM 2.50.0 / 4.20.6-arch1-1-ARCH, LLVM 7.0.1)","extensions":["ANGLE_instanced_arrays","EXT_blend_minmax","EXT_color_buffer_half_float","EXT_disjoint_timer_query","EXT_frag_depth","EXT_shader_texture_lod","EXT_texture_filter_anisotropic","WEBKIT_EXT_texture_filter_anisotropic","EXT_sRGB","OES_element_index_uint","OES_standard_derivatives","OES_texture_float","OES_texture_float_linear","OES_texture_half_float","OES_texture_half_float_linear","OES_vertex_array_object","WEBGL_color_buffer_float","WEBGL_compressed_texture_astc","WEBGL_compressed_texture_s3tc","WEBKIT_WEBGL_compressed_texture_s3tc","WEBGL_compressed_texture_s3tc_srgb","WEBGL_debug_renderer_info","WEBGL_debug_shaders","WEBGL_depth_texture","WEBKIT_WEBGL_depth_texture","WEBGL_draw_buffers","WEBGL_lose_context","WEBKIT_WEBGL_lose_context"]},"battery":{"charging":true,"level":1,"chargingTime":0,"dischargingTime":-1},"dnt":null,"math":{"tan":"-1.4214488238747245","sin":"0.8178819121159085","cos":"-0.5753861119575491"},"performance":{"timing":{"navigationStart":1549603734585,"unloadEventStart":1549603735458,"unloadEventEnd":1549603735459,"redirectStart":0,"redirectEnd":0,"fetchStart":1549603734586,"domainLookupStart":1549603734586,"domainLookupEnd":1549603734586,"connectStart":1549603734586,"connectEnd":1549603734586,"secureConnectionStart":0,"requestStart":1549603734590,"responseStart":1549603735451,"responseEnd":1549603735843,"domLoading":1549603735470,"domInteractive":1549603736045,"domContentLoadedEventStart":1549603736045,"domContentLoadedEventEnd":1549603736047,"domComplete":1549603736050,"loadEventStart":1549603736050,"loadEventEnd":1549603736054}},"end":1549604033967,"ciba":{"events":[{"startTime":543,"time":547,"type":"k"},{"startTime":549,"time":551,"type":"k"},{"time":554,"type":"mm","x":691,"y":238},{"time":778,"type":"mm","x":690,"y":237},{"time":888,"type":"mm","x":690,"y":224},{"time":1039,"type":"mm","x":690,"y":223},{"startTime":993,"time":1085,"type":"m"},{"time":1142,"type":"mm","x":690,"y":223},{"time":1255,"type":"mm","x":702,"y":247},{"time":1411,"type":"mm","x":647,"y":295},{"time":1521,"type":"mm","x":376,"y":234},{"startTime":1582,"time":1660,"type":"m"},{"time":1688,"type":"mm","x":377,"y":233},{"time":1788,"type":"mm","x":481,"y":242},{"time":1889,"type":"mm","x":655,"y":277},{"time":2007,"type":"mm","x":727,"y":295},{"time":2410,"type":"mm","x":728,"y":294},{"time":2521,"type":"mm","x":1417,"y":219},{"time":22606,"type":"mm","x":1572,"y":336},{"time":22706,"type":"mm","x":959,"y":204},{"time":22817,"type":"mm","x":941,"y":203},{"time":22923,"type":"mm","x":884,"y":251},{"time":23041,"type":"mm","x":818,"y":311},{"time":23167,"type":"mm","x":810,"y":320},{"time":23272,"type":"mm","x":788,"y":283},{"time":24142,"type":"mm","x":806,"y":538},{"time":24283,"type":"mm","x":807,"y":537},{"time":24691,"type":"mm","x":814,"y":538},{"time":24805,"type":"mm","x":913,"y":486},{"time":24905,"type":"mm","x":988,"y":463},{"time":25005,"type":"mm","x":995,"y":438},{"time":25105,"type":"mm","x":926,"y":323},{"time":25206,"type":"mm","x":856,"y":282},{"time":25306,"type":"mm","x":827,"y":288},{"time":25422,"type":"mm","x":813,"y":286},{"time":25586,"type":"mm","x":813,"y":286},{"startTime":25590,"time":25629,"type":"m"}],"start":1549603738619},"errors":[],"metrics":[{"n":"fwcim-instant-collector","t":0},{"n":"fwcim-element-telemetry-collector","t":1},{"n":"fwcim-script-version-collector","t":0},{"n":"fwcim-local-storage-identifier-collector","t":0},{"n":"fwcim-timezone-collector","t":1},{"n":"fwcim-script-collector","t":0},{"n":"fwcim-plugin-collector","t":0},{"n":"fwcim-capability-collector","t":0},{"n":"fwcim-browser-collector","t":0},{"n":"fwcim-history-collector","t":0},{"n":"fwcim-gpu-collector","t":2},{"n":"fwcim-battery-collector","t":1},{"n":"fwcim-dnt-collector","t":0},{"n":"fwcim-math-fingerprint-collector","t":0},{"n":"fwcim-performance-collector","t":0},{"n":"fwcim-timer-collector","t":0},{"n":"fwcim-ciba-collector","t":1},{"n":"fwcim-timer-collector","t":0}]}))

  raw_params = {} of String => Array(String)
  inputs.each { |key, value| raw_params[key] = [value] }

  body = HTTP::Params.new(raw_params).to_s

  headers["Referer"] = "https://www.amazon.com/ap/signin"
  headers["Content-Type"] = "application/x-www-form-urlencoded"

  response = client.post(signin_url, headers, body: body)
  File.write("response.html", response.body)
  headers = add_request_headers(response, headers)
end

def add_request_headers(response, headers)
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
