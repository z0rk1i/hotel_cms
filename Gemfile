source "https://rubygems.org"

# Web framework
gem "sinatra", "~> 4.1"
gem "rackup", "~> 2.2"
gem "puma", ">= 6.0"
gem "rake"

# Templates
gem "haml", "~> 6.0"

# Data
gem "activerecord", "~> 8.1"
gem "pg", "~> 1.1"

# Auth / security
gem "bcrypt", "~> 3.1"
gem "rack-protection", "~> 4.1"

# Mail
gem "mail", "~> 2.8"

# I18n (ru dates)
gem "i18n"

# Image thumbnails
gem "mini_magick", "~> 5.3"

# CSS build tool
gem "tailwindcss-ruby", "~> 4.0"

# CSV export (removed from default gems in Ruby 3.4)
gem "csv"

group :development, :test do
  gem "rspec", "~> 3.13"
  gem "rack-test", "~> 2.2"
  gem "factory_bot"
  gem "faker"
  gem "database_cleaner-active_record"
  gem "dotenv"
end

group :development do
  gem "rerun"
  gem "rubocop"
  gem "rubocop-rails-omakase"
  gem "letter_opener"
end
