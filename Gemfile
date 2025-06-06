# frozen_string_literal: true

ruby '3.2.1'

source 'https://rubygems.org'

gem 'addressable', '>= 2.8.0'
gem 'babel-transpiler'
gem 'bootstrap-sass', '>= 3.4.1'
gem 'bootstrap-tagsinput-rails'
gem 'coffee-rails'
gem 'devise', '~> 4.7'
gem 'ffi', '~> 1.15.4'
gem 'haml-rails'
gem 'jbuilder', '~> 2.0'
gem 'jquery-rails'
gem 'kaminari-actionview'
gem 'kaminari-mongoid'
gem 'loofah', '~> 2.2'
gem 'mongoid'
gem 'mongoid-simple-tags',
    git: 'https://github.com/simplificator/mongoid-simple-tags.git',
    ref: '940c575'
gem 'nokogiri', '>= 1.12.5'
gem 'rails', '7.0.4.2'
gem 'rack', '~> 2.1'
gem 'rack-attack'
gem 'rack-timeout'
gem 'rails-html-sanitizer', '~> 1.0'
gem 'recaptcha', '4.1.0', require: 'recaptcha/rails'
gem 'rubocop', '~> 0.66.0', require: false
gem 'ruby-oembed'
gem 'sass-rails'
gem 'sendgrid-actionmailer'
gem 'sprockets', '~> 4.0'
gem 'terser'
gem 'websocket-extensions', '>= 0.1.5'

group :development, :test do
  gem 'better_errors'
  gem 'byebug'
  gem 'capybara', '~> 3.18'
  gem 'dotenv-rails'
  gem 'factory_bot_rails', '~> 4.0'
  gem 'ffaker'
  gem 'launchy'
  gem 'rspec-rails'
end

group :test do
  gem 'webdrivers'
  gem 'climate_control'
  gem 'database_cleaner'
  gem 'fuubar'
  gem 'mongoid-rspec'
  gem 'rails-controller-testing'
  gem 'simplecov', require: false
  gem 'timecop'
  gem 'vcr'
  gem 'webmock', '~> 3.5'
end

group :development do
  gem 'web-console', '~> 2.0'
end

group :production do
  gem 'bson', '~> 4.0'
  gem 'puma', '~> 5.6.9'
  gem 'rails_12factor'
end
