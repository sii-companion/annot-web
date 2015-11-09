source 'https://rubygems.org'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '>= 4.2.0'
gem 'activesupport', '>= 4.2.2'


# Use sqlite3 as the database for Active Record
gem 'sqlite3'
# Use SCSS for stylesheets
gem 'sass-rails', '>= 3.2'
# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 2.7.2'
# Use CoffeeScript for .coffee assets and views
gem 'coffee-rails', '~> 4.1.0'
# See https://github.com/sstephenson/execjs#readme for more supported runtimes
# gem 'therubyracer', platforms: :ruby

# Use jquery as the JavaScript library
# we cannot use a later version as DataTables still uses undocumented behaviour
gem 'jquery-rails' , '= 3.1.3'

# Turbolinks makes following links in your web application faster. Read more: https://github.com/rails/turbolinks
#gem 'turbolinks'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.0'
# bundle exec rake doc:rails generates the API under doc/api.
gem 'sdoc', '~> 0.4.0', group: :doc

# Use ActiveModel has_secure_password
gem 'bcrypt', '~> 3.1.7'

# Use Unicorn as the app server
# gem 'unicorn'

# Use Capistrano for deployment
# gem 'capistrano-rails', group: :development
# gem 'capistrano-sidekiq', github: 'seuros/capistrano-sidekiq'
# gem 'capistrano-passenger'

group :development, :test do
  # Access an IRB console on exception pages or by using <%= console %> in views
  #gem 'web-console', '~> 2.0'

  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring', '1.2.0'
end

# easier linking with highlights
gem 'active_link_to'

# for executing external processes
gem 'open4'

# for async processing of background jobs
gem 'sidekiq', '>= 3.4.0'
gem 'sidekiq-status'
gem 'sidekiq-limit_fetch'

# upload/asset management (sequences, images, ...)
gem 'dragonfly'
group :production, :development do
  gem 'rack-cache', :require => 'rack/cache'
end

gem 'bootstrap-sass', '~> 3.3.3'
# gem 'remotipart', '~> 1.2'
gem 'autoprefixer-rails'

# JQuery extensions
gem 'jquery-ui-rails'
# gem 'jquery.fileupload-rails'
gem 'jasny_bootstrap_extension_rails'

# OAuth2 (e.g. Google)
#gem 'omniauth', '~> 1.2.2'
#gem 'omniauth-google-oauth2'

# for bulk import of data into ActiveRecord
gem 'activerecord-import', '~> 0.4.0'

# better tables
gem 'jquery-datatables-rails', '~> 3.3.0'

# for the reference definitions
gem 'active_hash'
gem 'json'

# Production replacement for WEBrick
gem 'thin'

# Captcha
gem "recaptcha", :require => "recaptcha/rails"