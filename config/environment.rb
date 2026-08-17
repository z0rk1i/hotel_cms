ENV["APP_ENV"] ||= ENV["RACK_ENV"] || "development"

require "bundler/setup"
Bundler.require(:default, ENV["APP_ENV"].to_sym)

APP_ROOT = File.expand_path("..", __dir__)

require "erb"
require "yaml"
require "logger"
require "securerandom"
require "uri"
require "active_support/all"
require "active_record"
require "i18n"

Dotenv.load if %w[development test].include?(ENV["APP_ENV"])

# --- Database ---
require_relative "database"

# --- I18n ---
I18n.load_path += Dir[File.join(APP_ROOT, "config", "locales", "*.yml")]
I18n.available_locales = %i[ru en]
I18n.default_locale = :ru
I18n.fallbacks = [ :en ]

# Same default as the Rails app (config.time_zone unset => UTC).
# Time.zone= only sets the current thread; zone_default is process-wide,
# so worker threads in puma see the default too.
Time.zone_default = Time.find_zone!("UTC")

# --- Mail ---
require_relative "mail"

# --- Application code ---
require_relative "../app/models/application_record"
%w[room room_photo user stay report].each { |m| require_relative "../app/models/#{m}" }
require_relative "../app/services/static_content"
require_relative "../app/services/reports/builder"
require_relative "../app/helpers/application_helper"
require_relative "../app/helpers/admin_helper"
require_relative "../app/helpers/app_support"
require_relative "../app/helpers/routes"
require_relative "../app/mailers/booking_mailer"
