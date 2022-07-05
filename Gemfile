source 'https://rubygems.org'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '>= 4.2.0'
gem 'activesupport', '>= 4.2.2'

# Use mysql2 as the database for Active Record
gem 'mysql2'
# Use SCSS for stylesheets
gem 'sass-rails', '>= 3.2'
# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 2.7.2'
# Use CoffeeScript for .coffee assets and views
gem 'coffee-rails', '~> 4.1.0'

# Use jquery as the JavaScript library
gem 'jquery-rails', '~> 4.3', '>= 4.3.3'

# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.0'
# bundle exec rake doc:rails generates the API under doc/api.
# gem 'sdoc', '~> 0.4.0', group: :doc

# Use ActiveModel has_secure_password
gem 'bcrypt', '~> 3.1.7'

# Use Capistrano for deployment
# gem 'capistrano-rails', group: :development
# gem 'capistrano-sidekiq', github: 'seuros/capistrano-sidekiq'
# gem 'capistrano-passenger'

group :development, :test do
  # Spring speeds up development by keeping your application
  # running in the background. Read more: https://github.com/rails/spring
  gem 'spring', '1.2.0'
  gem 'ruby-debug-ide'
  gem 'debase'
end

# easier linking with highlights
gem 'active_link_to'

# for executing external processes
gem 'open4'

# for async processing of background jobs
gem 'sidekiq', '>= 6.4.1'
gem 'sidekiq-status'
gem 'sidekiq-limit_fetch'

# upload/asset management (sequences, images, ...)
gem 'dragonfly'

# caching
group :production, :development do
  gem 'rack', '~> 2.0'
  gem 'rack-cache', :require => 'rack/cache'
end

# Bootstrap
gem 'bootstrap-sass', '~> 3.3.3'
gem 'autoprefixer-rails'

# JQuery extensions
gem 'jquery-ui-rails'

# for bulk import of data into ActiveRecord
# require at least v0.18.3 for :on_duplicate_key_ignore option to work
gem 'activerecord-import', '>= 0.18.3'


# for the reference definitions
gem 'active_hash'
gem 'json', '>= 2.0.0'

# Production replacement for WEBrick
gem 'thin'

# Captcha
gem 'simple_captcha2', '= 0.5.0', require: 'simple_captcha'

# for efficient on-the-fly zipping
gem "rubyzip", :require => 'zip'

# for gathering filesystem information
gem "sys-filesystem", :require => 'sys/filesystem'

# sitemap handling
gem 'sitemap_generator'
gem 'lol_dba'

# worker startup
gem 'foreman'

gem 'bigdecimal', '1.3.5'
gem 'execjs', '2.7.0'
