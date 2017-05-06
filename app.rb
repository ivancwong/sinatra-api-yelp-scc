# Require the bundler gem and then call Bundler.require to load in all gems
# listed in Gemfile.
require 'sinatra'
require 'sinatra/cross_origin'
require 'bundler'

# Yelp Code
require "json"
require "http"
# require "optparse"
# end Yelp Code

Bundler.require


# Setup DataMapper with a database URL. On Heroku, ENV['DATABASE_URL'] will be
# set, when working locally this line will fall back to using SQLite in the
# current directory.
DataMapper.setup(:default, ENV['DATABASE_URL'] || "sqlite://#{Dir.pwd}/development.sqlite")

# Define a simple DataMapper model.
class Business
  include DataMapper::Resource

  property :id, Serial, :key => true
  property :created_at, DateTime
  property :yelp_id, String
  property :yelp_name, String, :length =>255
  property :image_url, String, :length =>255
  property :is_claimed, Boolean
  property :is_closed, Boolean
  property :url, String, :length =>255
  property :price, String
  property :rating, Decimal, :precision => 10, :scale => 2
  property :review_count, Integer
  property :phone, String
  property :photo1_url, String, :length =>255
  property :photo2_url, String, :length =>255
  property :photo3_url, String, :length =>255
  property :coordinates_latitude, Float
  property :coordinates_longitude, Float
end

class Review
  include DataMapper::Resource

  property :id, Serial, :key => true
  property :created_at, DateTime
  property :yelp_id, String
  property :rating, Integer
  property :yelp_user_image_url, String, :length => 255
  property :yelp_user_name, String
  property :text, Text
  property :review_created_at, DateTime
  property :business_url, String, :length =>255
  property :business_review_count, Integer
end

# Finalize the DataMapper models.
DataMapper.finalize

# Tell DataMapper to update the database according to the definitions above.
DataMapper.auto_upgrade!

# To enable cross origin requests for all routes:
configure do
  enable :cross_origin
end


# =========================== Routes for Service Status Check index.html Page ===================================


get '/' do
  send_file './public/index.html'
end



# =========================== Routes for Business ===================================

# Route to show all businesses, ordered like a blog
get '/businesses' do
  content_type :json
  @businesses = Business.all(:order => :created_at.desc)

  @businesses.to_json
end

# CREATE: Route to create a new Business
post '/businesses' do
  content_type :json

  # These next commented lines are for if you are using Backbone.js
  # JSON is sent in the body of the http request. We need to parse the body
  # from a string into JSON
  # params_json = JSON.parse(request.body.read)

  # If you are using jQuery's ajax functions, the data goes through in the
  # params.
  @business = Business.new(params)

  if @business.save
    @business.to_json
  else
    halt 500
  end

end

# READ: Route to show a specific Business based on its `id`
get '/businesses/:id' do
  content_type :json
  @business = Business.get(params[:id].to_i)

  # ========  Refresh Reviews and Update database using the Business ID (yelp_id)

  puts "I am the Yelp Business ID =  " + @business['yelp_id']
  # ===============================================
  # Making a call for review lookup and refresh Database
  yelp_review_lookup(@business['yelp_id'])
  # end of Making a call for review lookup

  # ===============================================

  if @business
    @business.to_json
  else
    halt 404
  end


end

# UPDATE: Route to update a Business
put '/businesses/:id' do
  content_type :json

  # These next commented lines are for if you are using Backbone.js
  # JSON is sent in the body of the http request. We need to parse the body
  # from a string into JSON
  # params_json = JSON.parse(request.body.read)

  # If you are using jQuery's ajax functions, the data goes through in the
  # params.

  @business = Business.get(params[:id].to_i)
  @business.update(params)

  if @business.save
    @business.to_json
  else
    halt 500
  end
end

# DELETE: Route to delete a Business
delete '/businesses/:id/delete' do
  content_type :json
  @business = Business.get(params[:id].to_i)

  if @business.destroy
    {:success => "ok"}.to_json
  else
    halt 500
  end
end


# =========================== Routes for Review ===================================

# Route to show all reviews, ordered like a blog
get '/reviews' do
  content_type :json
  @reviews = Review.all(:order => :created_at.desc)

  @reviews.to_json
end

# CREATE: Route to create a new Reviews
post '/reviews' do
  content_type :json

  # These next commented lines are for if you are using Backbone.js
  # JSON is sent in the body of the http request. We need to parse the body
  # from a string into JSON
  # params_json = JSON.parse(request.body.read)

  # If you are using jQuery's ajax functions, the data goes through in the
  # params.
  @review = Review.new(params)

  if @review.save
    @review.to_json
  else
    halt 500
  end
end

# READ: Route to show a specific Reviews based on its `id`
get '/reviews/:id' do
  content_type :json
  @review = Review.get(params[:id].to_i)

  if @review
    @review.to_json
  else
    halt 404
  end
end

# UPDATE: Route to update a Reviews
put '/reviews/:id' do
  content_type :json

  # These next commented lines are for if you are using Backbone.js
  # JSON is sent in the body of the http request. We need to parse the body
  # from a string into JSON
  # params_json = JSON.parse(request.body.read)

  # If you are using jQuery's ajax functions, the data goes through in the
  # params.

  @review = Review.get(params[:id].to_i)
  @review.update(params)

  if @review.save
    @review.to_json
  else
    halt 500
  end
end

# DELETE: Route to delete a Reviews
delete '/reviews/:id/delete' do
  content_type :json
  @review = Review.get(params[:id].to_i)

  if @review.destroy
    {:success => "ok"}.to_json
  else
    halt 500
  end
end




# ===========================  Seed Database  ===================================


# If there are no Business in the database, add a few.
if Business.count == 0
  # Using save command to get debugging code.
  puts "I am in Business Create."
  @business = Business.new(:yelp_id => "gary-danko-san-francisco",
                  :yelp_name => "Gary Danko",
                  :image_url => "https://s3-media4.fl.yelpcdn.com/bphoto/--8oiPVp0AsjoWHqaY1rDQ/o.jpg",
                  :is_claimed => false,
                  :is_closed => false,
                  :url => "https://www.yelp.com/biz/gary-danko-san-francisco",
                  :price => "$$$$",
                  :rating => 4.5,
                  :review_count => 4521,
                  :phone => "+14152520800",
                  :photo1_url =>  "http://s3-media3.fl.yelpcdn.com/bphoto/--8oiPVp0AsjoWHqaY1rDQ/o.jpg",
                  :photo2_url =>  "http://s3-media2.fl.yelpcdn.com/bphoto/ybXbObsm7QGw3SGPA1_WXA/o.jpg",
                  :photo3_url =>  "http://s3-media3.fl.yelpcdn.com/bphoto/7rZ061Wm4tRZ-iwAhkRSFA/o.jpg",
                  :coordinates_latitude => 37.80587,
                  :coordinates_longitude => -122.42058)

  @business.save

  @business.errors.each do |error|
    puts error
  end


  # Using create command to create record in one-short.
  Business.create(:yelp_id => "molinari-delicatessen-san-francisco",
                  :yelp_name =>  "Molinari Delicatessen",
                  :image_url => "https://s3-media4.fl.yelpcdn.com/bphoto/--8oiPVp0AsjoWHqaY1rDQ/o.jpg",
                  :is_claimed => false,
                  :is_closed => false,
                  :url => "https://www.yelp.com/biz/molinari-delicatessen-san-francisco",
                  :price => "$$$$",
                  :rating => 4.5,
                  :review_count => 4521,
                  :phone => "+14152520800",
                  :photo1_url =>  "http://s3-media3.fl.yelpcdn.com/bphoto/--8oiPVp0AsjoWHqaY1rDQ/o.jpg",
                  :photo2_url =>  "http://s3-media2.fl.yelpcdn.com/bphoto/ybXbObsm7QGw3SGPA1_WXA/o.jpg",
                  :photo3_url =>  "http://s3-media3.fl.yelpcdn.com/bphoto/7rZ061Wm4tRZ-iwAhkRSFA/o.jpg",
                  :coordinates_latitude => 37.7983818054199,
                  :coordinates_longitude => -122.407821655273)
end

# If there are no Review in the database, add a few.

if Review.count == 0
  # Using save command to get debugging code.
  puts "I am in Business Create."
  @review = Review.new(    :yelp_id => "gary-danko-san-francisco",
                           :rating => 5,
                           :yelp_user_image_url =>  "https://s3-media3.fl.yelpcdn.com/photo/iwoAD12zkONZxJ94ChAaMg/o.jpg",
                           :yelp_user_name => "Ella A.",
                           :text => "Went back again to this place since the last time i visited the bay area 5 months ago, and nothing has changed. Still the sketchy Mission, Still the cashier...",
                           :review_created_at => "2016-08-29 00:41:13",
                           :business_url => "https://www.yelp.com/biz/la-palma-mexicatessen-san-francisco?hrid=hp8hAJ-AnlpqxCCu7kyCWA&adjust_creative=0sidDfoTIHle5vvHEBvF0w&utm_campaign=yelp_api_v3&utm_medium=api_v3_business_reviews&utm_source=0sidDfoTIHle5vvHEBvF0w",
                           :business_review_count =>  10)


  @review.save

  @review.errors.each do |error|
    puts error
  end


  Review.create( :yelp_id => "gary-danko-san-francisco",
                 :rating => 4,
                 :yelp_user_image_url =>  "https://s3-media3.fl.yelpcdn.com/photo/iwoAD12zkONZxJ94ChAaMg/o.jpg",
                 :yelp_user_name => "Yanni L.",
                 :text => "The \"restaurant\" is inside a small deli so there is no sit down area. Just grab and go.\n\nInside, they sell individually packaged ingredients so that you can...",
                 :review_created_at => "2016-09-28 08:55:29",
                 :business_url => "https://www.yelp.com/biz/la-palma-mexicatessen-san-francisco?hrid=hp8hAJ-AnlpqxCCu7kyCWA&adjust_creative=0sidDfoTIHle5vvHEBvF0w&utm_campaign=yelp_api_v3&utm_medium=api_v3_business_reviews&utm_source=0sidDfoTIHle5vvHEBvF0w",
                 :business_review_count =>  10)

end


# ================= Yelp Code =============


# Place holders for Yelp Fusion's OAuth 2.0 credentials. Grab them
# from https://www.yelp.com/developers/v3/manage_app
CLIENT_ID = "GgaSroKMoHb0bSSkfVFEfw"
CLIENT_SECRET = "BmyB64vaBNSjlk125W5irUpPDobx0DnMLT4DaRIlQFDFDJL7WSmD4j3KWhI578r3"


# Constants, do not change these
API_HOST = "https://api.yelp.com"
SEARCH_PATH = "/v3/businesses/search"
BUSINESS_PATH = "/v3/businesses/"  # trailing / because we append the business id to the path
TOKEN_PATH = "/oauth2/token"
GRANT_TYPE = "client_credentials"


DEFAULT_BUSINESS_ID = "yelp-san-francisco"
DEFAULT_TERM = "dinner"
DEFAULT_LOCATION = "San Francisco, CA"
SEARCH_LIMIT = 5


# Make a request to the Fusion API token endpoint to get the access token.
#
# host - the API's host
# path - the oauth2 token path
#
# Examples
#
#   bearer_token
#   # => "Bearer some_fake_access_token"
#
# Returns your access token
def bearer_token
  # Put the url together
  url = "#{API_HOST}#{TOKEN_PATH}"

  raise "Please set your CLIENT_ID" if CLIENT_ID.nil?
  raise "Please set your CLIENT_SECRET" if CLIENT_SECRET.nil?

  # Build our params hash
  params = {
      client_id: CLIENT_ID,
      client_secret: CLIENT_SECRET,
      grant_type: GRANT_TYPE
  }

  response = HTTP.post(url, params: params)
  parsed = response.parse

  "#{parsed['token_type']} #{parsed['access_token']}"
end


# Make a request to the Fusion search endpoint. Full documentation is online at:
# https://www.yelp.com/developers/documentation/v3/business_search
#
# term - search term used to find businesses
# location - what geographic location the search should happen
#
# Examples
#
#   search("burrito", "san francisco")
#   # => {
#          "total": 1000000,
#          "businesses": [
#            "name": "El Farolito"
#            ...
#          ]
#        }
#
#   search("sea food", "Seattle")
#   # => {
#          "total": 1432,
#          "businesses": [
#            "name": "Taylor Shellfish Farms"
#            ...
#          ]
#        }
#
# Returns a parsed json object of the request
def search(term, location)
  url = "#{API_HOST}#{SEARCH_PATH}"
  params = {
      term: term,
      location: location,
      limit: SEARCH_LIMIT
  }

  response = HTTP.auth(bearer_token).get(url, params: params)
  response.parse
end

# ===============================================
# Look up a business by a given business id. Full documentation is online at:
# https://www.yelp.com/developers/documentation/v3/business
#
# business_id - a string business id
#
# Examples
#
#   business("yelp-san-francisco")
#   # => {
#          "name": "Yelp",
#          "id": "yelp-san-francisco"
#          ...
#        }
#
# Returns a parsed json object of the request
def business(business_id)
  url = "#{API_HOST}#{BUSINESS_PATH}#{business_id}"

  response = HTTP.auth(bearer_token).get(url)
  response.parse
end


# ===============================================
# Look up a review by a given business id. Full documentation is online at:
# https://www.yelp.com/developers/documentation/v3/business/reviews
#
# business_id - a string business id
#
# Examples
#
#   business("yelp-san-francisco")
#   # => {
#          "name": "Yelp",
#          "id": "yelp-san-francisco"
#          ...
#        }
#
# Returns a parsed json object of the request
def review(business_id)
  url = "#{API_HOST}#{BUSINESS_PATH}#{business_id}" + "/reviews"

  response = HTTP.auth(bearer_token).get(url)
  response.parse
end




# ===============================================
# Function for Yelp Business Look up using Yelp Business ID.
def yelp_business_lookup(business_id)
    response = business(business_id)

    puts "Found business with id #{business_id}:"
    puts JSON.pretty_generate(response)

    puts response

    puts response['id']
    puts response['name']
    puts response['image_url']
    puts response['photos'][0]
    puts response['photos'][1]
    puts response['photos'][2]
    puts response['coordinates']['latitude']
    puts response['coordinates']['longitude']
    puts response['price']


    #puts response['photos[1]']
    #puts response['photos[2]']

    #puts response['coordinates]['latitude']


    # Using create command to create record in one-short if the Business record not exists in the database.
    count = Business.count(:yelp_id => response['id'])
    puts "Business Record Count with this ID = " + count.to_s

    if Business.count(:yelp_id => response['id']) == 0

      Business.create(:yelp_id => response['id'],
                      :yelp_name =>  response['name'],
                      :image_url => response['image_url'],
                      :is_claimed => response['is_claimed'],
                      :is_closed => response['is_closed'],
                      :url => response['url'],
                      :price => '$$$$',
                      :rating => response['rating'],
                      :review_count => response['review_count'],
                      :phone => response['phone'],
                      :photo1_url =>  response['photos'][0],
                      :photo2_url =>  response['photos'][1],
                      :photo3_url =>  response['photos'][2],
                      :coordinates_latitude => response['coordinates']['latitude'],
                      :coordinates_longitude => response['coordinates']['longitude']
                      )
    end
end
# end of Yelp Business Look Up Function
# ===============================================



# ===============================================
# Function for Yelp Business Look up using Yelp Business ID.
def yelp_review_lookup(business_id)

    response = review(business_id)

    puts "Found review with id #{business_id}:"
    puts JSON.pretty_generate(response)


    # Print 1st Review
    puts response['reviews'][0]['url']
    puts response['reviews'][0]['text']
    puts response['reviews'][0]['rating']
    puts response['reviews'][0]['user']['image_url']
    puts response['reviews'][0]['user']['name']
    puts response['reviews'][0]['time_created']
    puts response['total']

    # Using create command to create record in one-short if the Reviews record not exists in the database.
    count0 = Review.count(:yelp_id => business_id, :review_created_at => response['reviews'][0]['time_created'])
    puts "Review Record [0] Count0 with this ID and Timestamp= " + count0.to_s

    count1 = Review.count(:yelp_id => business_id, :review_created_at => response['reviews'][1]['time_created'])
    puts "Review Record [1] Count1 with this ID and Timestamp= " + count1.to_s

    count2 = Review.count(:yelp_id => business_id, :review_created_at => response['reviews'][2]['time_created'])
    puts "Review Record [2] Count2 with this ID and Timestamp= " + count2.to_s


    if Review.count(:yelp_id => business_id, :review_created_at => response['reviews'][0]['time_created']) == 0

      Review.create( :yelp_id => business_id,
                     :rating => response['reviews'][0]['rating'],
                     :yelp_user_image_url =>  response['reviews'][0]['user']['image_url'],
                     :yelp_user_name => response['reviews'][0]['user']['name'],
                     :text => response['reviews'][0]['text'],
                     :review_created_at => response['reviews'][0]['time_created'],
                     :business_url => response['reviews'][0]['url'],
                     :business_review_count =>  response['total']
                    )
    end

    if Review.count(:yelp_id => business_id, :review_created_at => response['reviews'][1]['time_created']) == 0

      Review.create( :yelp_id => business_id,
                     :rating => response['reviews'][1]['rating'],
                     :yelp_user_image_url =>  response['reviews'][1]['user']['image_url'],
                     :yelp_user_name => response['reviews'][1]['user']['name'],
                     :text => response['reviews'][1]['text'],
                     :review_created_at => response['reviews'][1]['time_created'],
                     :business_url => response['reviews'][1]['url'],
                     :business_review_count =>  response['total']
      )
    end

    if Review.count(:yelp_id => business_id, :review_created_at => response['reviews'][2]['time_created']) == 0

      Review.create( :yelp_id => business_id,
                     :rating => response['reviews'][2]['rating'],
                     :yelp_user_image_url =>  response['reviews'][2]['user']['image_url'],
                     :yelp_user_name => response['reviews'][2]['user']['name'],
                     :text => response['reviews'][2]['text'],
                     :review_created_at => response['reviews'][2]['time_created'],
                     :business_url => response['reviews'][2]['url'],
                     :business_review_count =>  response['total']
      )
    end
end

# end of Making a call for review lookup
# ===============================================





=begin


options = {}
OptionParser.new do |opts|
  opts.banner = "Example usage: ruby sample.rb (search|lookup) [options]"

  opts.on("-tTERM", "--term=TERM", "Search term (for search)") do |term|
    options[:term] = term
  end

  opts.on("-lLOCATION", "--location=LOCATION", "Search location (for search)") do |location|
    options[:location] = location
  end

  opts.on("-bBUSINESS_ID", "--business-id=BUSINESS_ID", "Business id (for lookup)") do |id|
    options[:business_id] = id
  end

  opts.on("-h", "--help", "Prints this help") do
    puts opts
    exit
  end
end.parse!


command = ARGV


case command.first
  when "search"
    term = options.fetch(:term, DEFAULT_TERM)
    location = options.fetch(:location, DEFAULT_LOCATION)

    raise "business_id is not a valid parameter for searching" if options.key?(:business_id)

    response = search(term, location)

    puts "Found #{response["total"]} businesses. Listing #{SEARCH_LIMIT}:"
    response["businesses"].each {|biz| puts biz["name"]}
  when "lookup"
    business_id = options.fetch(:business_id, DEFAULT_BUSINESS_ID)


    raise "term is not a valid parameter for lookup" if options.key?(:term)
    raise "location is not a valid parameter for lookup" if options.key?(:lookup)

    response = business(business_id)

    puts "Found business with id #{business_id}:"
    puts JSON.pretty_generate(response)
  else
    puts "Please specify a command: search or lookup"
end

=end

# ============== End Yelp Code =============



# ===============================================
# Making a call for business lookup
business_id = DEFAULT_BUSINESS_ID
yelp_business_lookup(business_id)
# end of Making a call for business lookup
# ===============================================

# ===============================================
# Making a call for review lookup
business_id = DEFAULT_BUSINESS_ID
yelp_review_lookup(business_id)
# end of Making a call for review lookup
# ===============================================