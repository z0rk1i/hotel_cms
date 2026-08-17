require "sinatra/base"
require "ipaddr"

# Shared base for the public (App) and admin (AdminApp) Sinatra applications.
# Holds common config, filters, error handling and reusable helpers so that
# app.rb and admin.rb contain only their own routes and logic.
class AppBase < Sinatra::Base
  set :root, APP_ROOT
  set :views, File.join(APP_ROOT, "app", "views")
  set :public_folder, File.join(APP_ROOT, "public")
  set :show_exceptions, false
  set :haml, escape_html: false
  set :raise_errors, ENV["APP_ENV"] == "test"
  set :session_secret, ENV.fetch("SESSION_SECRET", "dev-secret-hotel-cms-change-me-in-production-00000000000000000000000000")

  hosts = ENV.fetch("HOSTS", "").split(",").reject(&:empty?)
  set :host_authorization, ->() do
    if hosts.any?
      { permitted_hosts: hosts }
    else
      { permitted_hosts: [ "localhost", ".localhost", ".test", "example.org", "127.0.0.1", IPAddr.new("0.0.0.0/0"), IPAddr.new("::/0") ] }
    end
  end
  set :protection, except: [ :remote_token, :http_origin ]

  enable :sessions
  use Rack::MethodOverride

  helpers ApplicationHelper, RoutesHelper, AppSupport

  before do
    @flash = session.delete("flash") || {}
    protect_from_forgery
  end

  not_found do
    File.read(File.join(APP_ROOT, "public", "404.html"))
  end

  error ActiveRecord::RecordNotFound do
    status 404
    File.read(File.join(APP_ROOT, "public", "404.html"))
  end

  error do
    status 500
    File.read(File.join(APP_ROOT, "public", "500.html"))
  end

  private

  # Parses a date from a form/query value, falling back to +fallback+ when the
  # value is blank or unparseable. Used by admin stays/reports routes.
  def parse_date(value, fallback: nil)
    return fallback if value.blank?

    Date.parse(value)
  rescue Date::Error, ArgumentError, TypeError
    fallback
  end

  # Slices a nested params hash (e.g. params["room"]) down to the permitted keys.
  def slice_params(source, permitted)
    result = {}
    permitted.each do |key|
      result[key] = source&.[](key.to_s) if source&.key?(key.to_s)
    end
    result
  end
end
