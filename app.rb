# Require the bundler gem and then call Bundler.require to load in all gems
# listed in Gemfile.
require 'sinatra'
require 'sinatra/cross_origin'
require 'bundler'
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

get '/' do
  send_file './public/index.html'
end

# Route to show all businesses, ordered like a blog
get '/businesses' do
  content_type :json
  @businesses = Business.all(:order => :created_at.desc)

  @businesses.to_json
end

# CREATE: Route to create a new Thing
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

# READ: Route to show a specific Thing based on its `id`
get '/businesses/:id' do
  content_type :json
  @business = Business.get(params[:id].to_i)

  if @business
    @business.to_json
  else
    halt 404
  end
end

# UPDATE: Route to update a Thing
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

# DELETE: Route to delete a Thing
delete '/businesses/:id/delete' do
  content_type :json
  @business = Business.get(params[:id].to_i)

  if @business.destroy
    {:success => "ok"}.to_json
  else
    halt 500
  end
end


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