# audible.cr

WIP interface for internal Audible API.

## Installation

1. Add the dependency to your `shard.yml`:

```yaml
dependencies:
  audible:
    github: omarroth/audible.cr
```

2. Run `shards install`

## Usage

```crystal
require "audible"

login_object = Audible.login("EMAIL", "PASSWORD")
auth_register = Audible.auth_register(login_object)

tokens = auth_register["response"]["success"]["tokens"]
device_private_key = OpenSSL::RSA.new(tokens["mac_dms"]["device_private_key"].as_s)
adp_token = tokens["mac_dms"]["adp_token"].as_s
access_token = tokens["bearer"]["access_token"].as_s
refresh_token = tokens["bearer"]["refresh_token"].as_s

client = HTTP::Client.new(Audible::AUDIBLE_API)

request = sign_request(HTTP::Request.new("GET", "/0.0/library/books?purchaseAfterDate=01/01/1970"), adp_token, device_private_key)
client.exec(request).body # => <books><total_book_count>35</total_book_count><book><title>The Master and...
```

Clients should remember `access_token`, `refresh_token`, `adp_token`, `device_private_key` when possible.

Logging in currently requires answering a CAPTCHA. There will be a prompt for the above example that looks like this:

```
$ crystal src/audible.cr
https://opfcaptcha-prod.s3.amazonaws.com/...
Answer for CAPTCHA:
```

## Authentication

Request signing is fairly straight-forward. Signing uses the RSA key provided by `/auth/register`. Headers look like:

```
x-adp-alg: SHA256withRSA:1.0
x-adp-signature: AAAAAAAA...:2019-02-16T00:00:01.000000000Z,
x-adp-token: {enc:...}
```

It also appears to be possible to authenticate using:

```
Authentication: Bearer access_token
```

Although this has not been tested.

## Documentation:

There is currently no publicly available documentation about the Audible API. There is a node client ([audible-api](https://github.com/willthefirst/audible/tree/master/node_modules/audible-api)) that has some endpoints documented, but does not provide information on authentication.

Luckily the Audible API is partially self-documenting, however the parameter names need to be known. Error responses will look like:

```json
{
  "message": "1 validation error detected: Value 'some_random_string123' at 'numResults' failed to satisfy constraint: Member must satisfy regular expression pattern: ^\\d+$"
}
```

Very few endpoints have been fully documented, as a large amount of functionality is not testable from the app or functionality is unknown. Most calls need to be authenticated in the same way as in [usage](#Usage).

For `%s` substitutions the value is unknown or can be inferred from the endpoint. `/1.0/catalog/products/%s` for example requires an `asin`, as in `/1.0/catalog/products/B002V02KPU`.

Each bullet below refers to a parameter for the request with the specified method and URL.

Responses will often provide very little info without `response_groups` specified. Multiple response groups can be specified, for example: `/1.0/catalog/products/B002V02KPU?response_groups=product_plan_details,media,review_attrs`. When providing an invalid response group, the server will return an error response but will not provide any information on available response groups.

### GET /0.0/library/books

- purchaseAfterDate: mm/dd/yyyy

### GET /1.0/wishlist

- num_results: \\d+ (max: 50)
- page: \\d+
- response_groups: [contributors, media, price, product_attrs, product_desc, product_extended_attrs, product_plan_details, product_plans, rating, sample, sku]
- sort_by: [-DateAdded, Price, -Rating, Author, -Title, DateAdded, -Author, Title, -Price, Rating]

### POST /1.0/wishlist

- B asin : String

Example request body:

```json
{
  "asin": "B002V02KPU"
}
```

Returns 201 and a `Location` to the resource.

### DELETE /1.0/wishlist/%s

Returns 204 and removes the item from the wishlist using the given `asin`.

### GET /1.0/badges/progress

- locale: en_US
- response_groups: brag_message
- store: Audible

### GET /1.0/badges/metadata

- locale: en_US
- response_groups: all_levels_metadata

### GET /1.0/account/information

- response_groups: [delinquency_status, customer_benefits, subscription_details_payment_instrument, plan_summary, subscription_details]
- source: [Enterprise, RodizioFreeBasic, AyceRomance, AllYouCanEat, AmazonEnglish, ComplimentaryOriginalMemberBenefit, Radio, SpecialBenefit, Rodizio]

### POST(?) /1.0/library/collections/%s/channels/%s

- customer_id:
- marketplace:

### POST(?) /1.0/library/collections/%s/products/%s

- channel_id:

### GET /1.0/catalog/categories

- categories_num_levels: \\d+ (greater than or equal to 1)
- ids: \\d+(,\\d+)\*
- root: [InstitutionsHpMarketing, ChannelsConfigurator, AEReadster, ShortsPrime, ExploreBy, RodizioBuckets, EditorsPicks, ClientContent, RodizioGenres, AmazonEnglishProducts, ShortsSandbox, Genres, Curated, ShortsIntroOutroRemoval, Shorts, RodizioEpisodesAndSeries, ShortsCurated]

### GET /1.0/catalog/categories/%s

- image_dpi: \\d+
- image_sizes:
- image_variants:
- products_in_plan_timestamp:
- products_not_in_plan_timestamp:
- products_num_results: \\d+
- products_plan: [Enterprise, RodizioFreeBasic, AyceRomance, AllYouCanEat, AmazonEnglish, ComplimentaryOriginalMemberBenefit, Radio, SpecialBenefit, Rodizio]
- products_sort_by: [-ReleaseDate, ContentLevel, -Title, AmazonEnglish, AvgRating, BestSellers, -RuntimeLength, ReleaseDate, ProductSiteLaunchDate, -ContentLevel, Title, Relevance, RuntimeLength]
- reviews_num_results: \\d+
- reviews_sort_by: [MostHelpful, MostRecent]

### GET(?) /1.0/content/%s/licenserequest

- ?

### GET /1.0/content/%s/metadata

- acr:

### GET /1.0/customer/information

- response_groups: [migration_details, subscription_details_rodizio, subscription_details_premium, customer_segment, subscription_details_channels]

### GET /1.0/customer/status

- response_groups: [benefits_status, member_giving_status, prime_benefits_status, prospect_benefits_status]

### GET /1.0/customer/freetrial/eligibility

### GET /1.0/library/collections

- customer_id:
- marketplace:

### POST(?) /1.0/library/collections

- collection_type:

### GET /1.0/library/collections/%s

- customer_id:
- marketplace:
- page_size:
- continuation_token:

### GET /1.0/library/collections/%s/products

- customer_id:
- marketplace:
- page_size:
- continuation_token:
- image_sizes:

### GET /1.0/stats/status/finished

### POST(?) /1.0/stats/status/finished

- start_date:
- status:
- continuation_token:

### GET /1.0/pages/%s

%s: ios-app-home

- locale: en-US
- reviews_num_results:
- reviews_sort_by:
- response_groups: [media, product_plans, view, product_attrs, contributors, product_desc, sample]

### GET /1.0/catalog/products/%s

- image_dpi:
- image_sizes:
- response_groups: [contributors, media, product_attrs, product_desc, product_extended_attrs, product_plan_details, product_plans, rating, review_attrs, reviews, sample, sku]
- reviews_num_results: \\d+ (max: 10)
- reviews_sort_by: [MostHelpful, MostRecent]

### GET /1.0/catalog/products/%s/reviews

- sort_by: [MostHelpful, MostRecent]
- num_results: \\d+ (max: 50)
- page: \\d+

### GET /1.0/catalog/products

- author:
- browse_type:
- category_id: \\d+(,\\d+)\*
- disjunctive_category_ids:
- image_dpi: \\d+
- image_sizes:
- in_plan_timestamp:
- keywords:
- narrator:
- not_in_plan_timestamp:
- num_most_recent:
- num_results: \\d+ (max: 50)
- page: \\d+
- plan: [Enterprise, RodizioFreeBasic, AyceRomance, AllYouCanEat, AmazonEnglish, ComplimentaryOriginalMemberBenefit, Radio, SpecialBenefit, Rodizio]
- products_since_timestamp:
- products_sort_by: [-ReleaseDate, ContentLevel, -Title, AmazonEnglish, AvgRating, BestSellers, -RuntimeLength, ReleaseDate, ProductSiteLaunchDate, -ContentLevel, Title, Relevance, RuntimeLength]
- publisher:
- response_groups: [contributors, media, price, product_attrs, product_desc, product_extended_attrs, product_plan_detail, product_plans, rating, review_attrs, reviews, sample, sku]
- reviews_num_results: \\d+ (max: 10)
- reviews_sort_by: [MostHelpful, MostRecent]
- title:

### GET /1.0/recommendations

- category_image_variants:
- image_dpi:
- image_sizes:
- in_plan_timestamp:
- language:
- not_in_plan_timestamp:
- num_results: \\d+ (max: 50)
- plan: [Enterprise, RodizioFreeBasic, AyceRomance, AllYouCanEat, AmazonEnglish, ComplimentaryOriginalMemberBenefit, Radio, SpecialBenefit, Rodizio]
- response_groups: [contributors, media, price, product_attrs, product_desc, product_extended_attrs, product_plan_details, product_plans, rating, sample, sku]
- reviews_num_results: \\d+ (max: 10)
- reviews_sort_by: [MostHelpful, MostRecent]

### GET /1.0/catalog/products/%s/sims

- category_image_variants:
- image_dpi:
- image_sizes:
- in_plan_timestamp:
- language:
- not_in_plan_timestamp:
- num_results: \\d+ (max: 50)
- plan: [Enterprise, RodizioFreeBasic, AyceRomance, AllYouCanEat, AmazonEnglish, ComplimentaryOriginalMemberBenefit, Radio, SpecialBenefit, Rodizio]
- response_groups: [contributors, media, price, product_attrs, product_desc, product_extended_attrs, product_plans, rating, review_attrs, reviews, sample, sku]
- reviews_num_results: \\d+ (max: 10)
- reviews_sort_by: [MostHelpful, MostRecent]
- similarity_type: [InTheSameSeries, ByTheSameNarrator, RawSimilarities, ByTheSameAuthor, NextInSameSeries]

### POST(?) /1.0/library/item

- asin:

### POST(?) /1.0/library/item/%s/%s

## Downloading Books

Quite ugly, but the following will allow you to download the .aax for a given `asin`, provided the book is in your library:

```crystal
require "audible"

asin = "B002V5H6F4"

client = HTTP::Client.new(URI.parse("https://cde-ta-g7g.amazon.com"))
request = sign_request(
  HTTP::Request.new("GET", "/FionaCDEServiceEngine/FSDownloadContent?type=AUDI&currentTransportMethod=WIFI&key=#{asin}"),
  adp_token,
  device_private_key
)
response = client.exec(request)

client = HTTP::Client.new(URI.parse("https://cds.audible.com"))
request = sign_request(
  HTTP::Request.new("GET", response.headers["Location"]),
  adp_token,
  device_private_key
)

client.exec(request) do |response|
  filename = response.headers["Content-Disposition"].split("filename=")[1]
  content_length = response.headers["Content-Length"]
  file = File.open(filename, mode: "w")

  bytes_written = 0
  size = 1

  while size > 0
    size = IO.copy(response.body_io, file, 4096)
    bytes_written += size

    percentage = ((bytes_written.to_f / content_length.to_f) * 100).round(2)
    print "#{percentage}%\r"
    file.flush
  end
end

puts "100%   "

```

Assuming you have your activation bytes, you can convert .aax into another format with the following:

```
$ ffmpeg -activation_bytes 1CEB00DA -i test.aax -vn -c:a copy output.mp4
```

## Contributing

1. Fork it (<https://github.com/omarroth/audible.cr/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Omar Roth](https://github.com/omarroth) - creator and maintainer
