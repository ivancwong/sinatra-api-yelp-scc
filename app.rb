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

# Azure code
require 'net/http'
# end Azure code

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
  property :vision_gender, String
  property :vision_age, Integer
  property :vision_description_captions, Text
  property :vision_description_captions_confidence, Float
  property :emotion, String
  property :emotion_scores, Float
  property :sentiment, String
  property :sentiment_scores, Float
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
  # @businesses = Business.all(:order => :created_at.desc)
  @businesses = Business.all(:order => :yelp_id.asc)

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

=begin
  # ===============================================
  # Making a call for review Azure Analytics and refresh Database
  # update Review Vision, Emotion, and Text Analysis using Business Yelp_ID
  azure_review_update(@business['yelp_id'])
  # end of Making a call for Azure Analytics

  # ===============================================
=end

  if @business
    @business.to_json
  else
    halt 404
  end


end


# READ: Route to show a specific Business based on its `yelp_id`
get '/businesses_by_yelp_id/:yelp_id' do
  content_type :json
  #@business = Business.get(params[:yelp_id])
  #@business = Business.get(:yelp_id => params[:yelp_id])

  @businesses = Business.all(:yelp_id => params[:yelp_id])


  # ========  Refresh Reviews and Update database using the Business ID (yelp_id)

  puts "I am the Yelp Business ID =  " + @businesses[0]['yelp_id']
  # ===============================================
  # Making a call for review lookup and refresh Database
  yelp_review_lookup(@businesses[0]['yelp_id'])
  # end of Making a call for review lookup

  # ===============================================

  # ===============================================
  # Making a call for review Azure Analytics and refresh Database
  # update Review Vision, Emotion, and Text Analysis using Business Yelp_ID
  azure_review_update(@businesses[0]['yelp_id'])
  # end of Making a call for Azure Analytics

  # ===============================================

  if @businesses
    @businesses.to_json
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


# READ: Route to show All Reviews based on its `yelp_id`
get '/reviews_by_yelp_id/:yelp_id' do
  content_type :json
  @reviews = Review.all(:yelp_id => params[:yelp_id], :order => :review_created_at.desc)

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



# ========== Azure Code =========================

# update Review Vision, Emotion, and Text Analysis using Business Yelp_ID
def azure_review_update(business_id)

  # ======== Read from Database ===============
  @Reviews = Review.all(:yelp_id => business_id, :sentiment_scores => nil)

  # ======== Print Number of Reivew(s) to be processed ==========

  puts "======== Print Number of Reivew(s) to be processed.  Number of Record =  #{@Reviews.count} =========="

  # ========= Header Visual Analysis ============
  uri = URI('https://westus.api.cognitive.microsoft.com/vision/v1.0/analyze')
  uri.query = URI.encode_www_form({
                                      # Request parameters
                                      'visualFeatures' => 'Categories,Tags,Description,Faces,ImageType,Color,Adult',
                                      'details' => 'Celebrities,Landmarks',
                                      'language' => 'en'
                                  })


  request = Net::HTTP::Post.new(uri.request_uri)
  # Request headers
  request['Content-Type'] = 'application/json'
  # Request headers
  request['Ocp-Apim-Subscription-Key'] = 'd4382bec65e949019e4dc0c22930c68a'
  # ========= End Header Visual Analysis ============


  # ========= Header Emotion Analysis ============
  emotionUri = URI('https://westus.api.cognitive.microsoft.com/emotion/v1.0/recognize')
  emotionUri.query = URI.encode_www_form({
                                      # Request parameters

                                  })


  emotionRequest = Net::HTTP::Post.new(emotionUri.request_uri)
  # Request headers
  emotionRequest['Content-Type'] = 'application/json'
  # Request headers
  emotionRequest['Ocp-Apim-Subscription-Key'] = 'd97338a9cba2478eaeef18c5ba3906d1'
  # ========= End Header Emotion Analysis ============


  # ========= Header TEXT Analysis ============
  textUri =  URI('https://westus.api.cognitive.microsoft.com/text/analytics/v2.0/sentiment')
  textUri.query = URI.encode_www_form({
                                          # Request parameters

                                      })


  textRequest = Net::HTTP::Post.new(textUri.request_uri)
  # Request headers
  textRequest['Content-Type'] = 'application/json'
  # Request headers
  textRequest['Ocp-Apim-Subscription-Key'] = '5aca8bc9567f4d709a7c6a0940f56df6'
  # ========= End Header TEXT Analysis ============


  @Reviews.each do |a|

    puts "ID: #{a.id}   Name: #{a.yelp_user_name}."

# ========= Begin Azure Analysis ============

    # ============ Vision (Face) Analysis =======================

    @id = a.id
    @yelp_user_image_url    = a.yelp_user_image_url
    @reviewText = a.text

    # Request body
    # request.body = '{ "url": "https://s3-media1.fl.yelpcdn.com/photo/vZHtYkONDFEkm6E7KJW1_w/o.jpg"}'

    @reqString = '{ "url": "' + @yelp_user_image_url  + '" }'

    puts "========= Print Request String ========"
    puts @reqString
    request.body = @reqString

    response = Net::HTTP.start(uri.host, uri.port, :use_ssl => uri.scheme == 'https') do |http|
      http.request(request)
    end

    puts response.body

    parsedResponse = JSON.parse(response.body)

    puts "========== Print out Parsed Request ============"

    puts parsedResponse

    puts parsedResponse.keys

    puts "========== Print out the attributes =============="
    puts !parsedResponse['categories'].nil?

    if !parsedResponse['categories'].nil?
      puts parsedResponse['categories']
      puts parsedResponse['categories'][0]['name']
      puts parsedResponse['categories'][0]['score']

      puts parsedResponse['description']['captions']
      puts parsedResponse['description']['captions'][0]['text']
      puts parsedResponse['description']['captions'][0]['confidence']
    end

    if !parsedResponse['faces'].nil?
      puts parsedResponse['faces']
      puts parsedResponse['faces'][0].nil?

      if !parsedResponse['faces'][0].nil?
        puts parsedResponse['faces'][0]['gender']
        puts parsedResponse['faces'][0]['age']
      end
    end

    # Assign to variables -- Ready for DB update.
    if !parsedResponse['categories'].nil?
    @vision_description_captions = parsedResponse['description']['captions'][0]['text']
    @vision_description_captions_confidence = parsedResponse['description']['captions'][0]['confidence']
    else
      @vision_description_captions = nil
      @vision_description_captions_confidence = nil
    end

    if !parsedResponse['faces'].nil?
      if !parsedResponse['faces'][0].nil?
        @vision_gender = parsedResponse['faces'][0]['gender']
        @vision_age = parsedResponse['faces'][0]['age']
      else
        @vision_gender = nil
        @vision_age = nil
      end
    end

    # ============ End Vision (Face) Analysis =======================

    # =========== Emotion Analysis ===================================

    @emotionReqString = '{ "url": "' + @yelp_user_image_url  + '" }'

    puts "========= Print Request String ========"
    puts @emotionReqString
    emotionRequest.body = @emotionReqString

    emotionResponse = Net::HTTP.start(emotionUri.host, emotionUri.port, :use_ssl => emotionUri.scheme == 'https') do |http|
      http.request(emotionRequest)
    end

    puts emotionResponse.body

    parsedEmotionResponse = JSON.parse(emotionResponse.body)

    puts "========== Print out EMOTION Parsed Request ============"

    puts parsedEmotionResponse

    puts parsedEmotionResponse[0].nil?

    if !parsedEmotionResponse[0].nil?
       puts parsedEmotionResponse[0].keys
       puts parsedEmotionResponse[0]['scores']
       puts parsedEmotionResponse[0]['scores'].keys[0]
       puts parsedEmotionResponse[0]['scores'][0]



       puts "%.20f" % parsedEmotionResponse[0]['scores']['anger'].to_f
       puts "%.20f" % parsedEmotionResponse[0]['scores']['contempt'].to_f
       puts "%.20f" % parsedEmotionResponse[0]['scores']['disgust'].to_f
       puts "%.20f" % parsedEmotionResponse[0]['scores']['fear'].to_f
       puts "%.20f" % parsedEmotionResponse[0]['scores']['happiness'].to_f
       puts "%.20f" % parsedEmotionResponse[0]['scores']['neutral'].to_f
       puts "%.20f" % parsedEmotionResponse[0]['scores']['sadness'].to_f
       puts "%.20f" % parsedEmotionResponse[0]['scores']['surprise'].to_f



       emotionArray = [
           [parsedEmotionResponse[0]['scores'].keys[0], "%.20f" % parsedEmotionResponse[0]['scores']['anger'].to_f],
           [parsedEmotionResponse[0]['scores'].keys[1], "%.20f" % parsedEmotionResponse[0]['scores']['contempt'].to_f],
           [parsedEmotionResponse[0]['scores'].keys[2], "%.20f" % parsedEmotionResponse[0]['scores']['disgust'].to_f],
           [parsedEmotionResponse[0]['scores'].keys[3], "%.20f" % parsedEmotionResponse[0]['scores']['fear'].to_f],
           [parsedEmotionResponse[0]['scores'].keys[4], "%.20f" % parsedEmotionResponse[0]['scores']['happiness'].to_f],
           [parsedEmotionResponse[0]['scores'].keys[5], "%.20f" % parsedEmotionResponse[0]['scores']['neutral'].to_f],
           [parsedEmotionResponse[0]['scores'].keys[6], "%.20f" % parsedEmotionResponse[0]['scores']['sadness'].to_f],
           [parsedEmotionResponse[0]['scores'].keys[7], "%.20f" % parsedEmotionResponse[0]['scores']['surprise'].to_f]
       ]





       emotionArray.each do |(x, y)|
         puts "x =  #{x}  y =  #{y}"
       end

       sortedEmotionArray = emotionArray.sort_by(&:last).reverse

       sortedEmotionArray.each do |(x, y)|
         puts "SORTED x =  #{x}  y =  #{y}"
       end

       puts sortedEmotionArray[0][0]
       puts sortedEmotionArray[0][1]
       @emotion = sortedEmotionArray[0][0]
       @emotion_scores= sortedEmotionArray[0][1]


    end

    # =========== End Emotion Analysis ===================================

    # =========== TEXT Analysis ===================================

    @myString = @reviewText


    puts @myString.gsub('"', '\"')        # Escape Double quote ( " )
    puts @myString.gsub("'", "\\\\'")     # Escape Single quot ( ' )

    puts "======= Print subtString ======"

    @subtString =  @myString.gsub('"', '\"')     # Escape Double quote ( " )
    @subtString =  @subtString.gsub("'", "\\\\'")   # Escape Single quot ( ' )

    puts @subtString


    @textReqString = '{ "documents": [{"id": "1","text": "' + @subtString + '" }]}'

    puts "========= Print Request String ========"
    puts @textReqString
    textRequest.body = @textReqString

    textResponse = Net::HTTP.start(textUri.host, textUri.port, :use_ssl => textUri.scheme == 'https') do |http|
      http.request(textRequest)
    end

    puts textResponse.body

    parsedtextResponse = JSON.parse(textResponse.body)

    puts "========== Print out text Parsed Request ============"

    puts parsedtextResponse

    puts parsedtextResponse.nil?

    if !parsedtextResponse.nil?
      puts parsedtextResponse.keys
      puts parsedtextResponse['documents'][0]['score']
    end


    if  parsedtextResponse['documents'][0]['score'].to_f <= 0.33333 then
      puts "Negative"
      @sentiment = "Negative"

    elsif parsedtextResponse['documents'][0]['score'].to_f >= 0.66666 then
      puts "Positive"
      @sentiment = "Positive"

    elsif parsedtextResponse['documents'][0]['score'].to_f > 0.33333 &&
          parsedtextResponse['documents'][0]['score'].to_f < 0.66666 then
      puts "neutral"
      @sentiment = "neutral"
    end


    @sentiment_scores =  parsedtextResponse['documents'][0]['score']


   # =========== End TEXT Analysis ===================================

# ========= End Azure Analysis ============

   # ============ Review Record Update ===============================

    a.update(:vision_gender => @vision_gender,
             :vision_age => @vision_age,
             :vision_description_captions => @vision_description_captions,
             :vision_description_captions_confidence => @vision_description_captions_confidence,
             :emotion => @emotion,
             :emotion_scores => @emotion_scores,
             :sentiment => @sentiment,
             :sentiment_scores => @sentiment_scores
    )

    # RESET All Variables
      @vision_gender = nil
      @vision_age = nil
      @@vision_description_captions = nil
      @vision_description_captions_confidence = nil
      @emotion = nil
      @emotion_scores = nil
      @sentiment = nil
      @sentiment_scores = nil

   # ========== End Review Record Update =============================

  end


end


# ========= End Azure Code =====================

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

# ===============================================
# Making a call for review Azure Analytics and refresh Database
# update Review Vision, Emotion, and Text Analysis using Business Yelp_ID
business_id = DEFAULT_BUSINESS_ID
azure_review_update(business_id)
# end of Making a call for Azure Analytics

# ===============================================
