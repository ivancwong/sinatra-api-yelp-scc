source 'https://rubygems.org'
gem 'sinatra'
gem "sinatra-cross_origin", "~> 0.3.1"

gem 'json'

gem 'data_mapper'


# When developing an app locally you can use SQLite which is a relational
# database stored in a file. It's easy to set up and just fine for most
# development situations.
#group :development do
#  gem 'dm-sqlite-adapter'
#end

# Heroku uses Postgres however, so we tell the Gemfile to use Postgres
# in production instead of SQLite.
#group :production do
#  gem 'dm-postgres-adapter'
#end

#  Load postgres adapter
gem 'pg', :group => :production
gem 'dm-postgres-adapter', :group => :production
gem 'dm-sqlite-adapter', :group => :development