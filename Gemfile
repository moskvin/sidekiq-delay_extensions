# frozen_string_literal: true

source 'https://rubygems.org'

gemspec

gem 'activerecord-jdbcsqlite3-adapter', platforms: :jruby
gem 'rails', '>= 6.0.2'
gem 'rake'
gem 'redis-namespace'
gem 'sidekiq', '< 8'
gem 'sqlite3', platforms: :ruby

# mail dependencies
gem 'net-smtp', platforms: :mri, require: false

group :test do
  gem 'codecov', require: false
  gem 'minitest'
  gem 'simplecov'
end

group :development, :test do
  gem 'standard', require: false
  gem 'rubocop', require: false
end

group :load_test do
  gem 'hiredis'
  gem 'toxiproxy'
end
