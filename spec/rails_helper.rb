ENV["APP_ENV"] ||= "test"
require "spec_helper"
require_relative "../config/environment"
require_relative "../app"
require_relative "../admin"
require "rack/test"
require "factory_bot"
require "database_cleaner/active_record"
require "json"

Dir[File.join(APP_ROOT, "spec", "support", "**", "*.rb")].sort.each { |f| require f }
Dir[File.join(APP_ROOT, "spec", "factories", "*.rb")].sort.each { |f| require f }

# Defined with a guard: rspec can load this file under two different relative
# paths (./spec/... and ../spec/...), which would otherwise re-define the
# constant and emit "already initialized constant CODES" warnings.
CODES = {
  ok: 200, created: 201, redirect: 302, bad_request: 400,
  forbidden: 403, not_found: 404, unprocessable_entity: 422,
  internal_server_error: 500
}.freeze unless defined?(CODES)

RSpec::Matchers.define :have_http_status do |status|
  match do |response|
    response.status == (CODES[status] || status)
  end

  failure_message do |response|
    "expected response to have HTTP status #{status.inspect}, got #{response.status}"
  end
end

RSpec::Matchers.define :redirect_to do |expected|
  match do |response|
    location = response.location.to_s
    location == expected || location.end_with?(expected)
  end

  failure_message do |response|
    "expected response to redirect to #{expected.inspect}, got #{response.location.inspect}"
  end
end

class Rack::MockResponse
  def parsed_body
    JSON.parse(body)
  end
end

# Rack::Test verbs take params positionally; specs call them Rails-style with a
# `params:` keyword. Normalize so both forms work.
Rack::Test::Methods.instance_methods(false).each do |m|
  next unless %i[get post put patch delete head options].include?(m)

  Rack::Test::Methods.class_eval do
    alias_method :"rack_#{m}", m
    define_method(m) do |uri, params = {}, env = {}, &block|
      if params.is_a?(Hash) && params.key?(:params)
        kw = params
        params = kw.delete(:params) || {}
        env = kw.delete(:env) || env
      end
      send(:"rack_#{m}", uri, params, env, &block)
    end
  end
end

module RequestSpecHelpers
  include RoutesHelper
  def app
    @app ||= Rack::Builder.new do
      map("/admin") { run AdminApp }
      map("/") { run App }
    end
  end

  def response
    last_response
  end

  def flash
    session = last_request.session || {}
    (session["flash"] || {}).transform_keys(&:to_sym)
  end

  def sign_in(user)
    post "/admin/users/sign_in", { email: user.email, password: user.password }
    follow_redirect! if last_response.status == 302
  end

  def account_url(phone: nil)
    "http://localhost:3000/account"
  end
end

RSpec.configure do |config|
  config.include FactoryBot::Syntax::Methods
  config.include StayHelpers
  config.include Rack::Test::Methods, type: :request
  config.include RequestSpecHelpers, type: :request
  config.include RequestSpecHelpers, type: :mailer

  config.before(:suite) do
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.clean_with(:truncation)
  end

  config.before do
    DatabaseCleaner.start
  end

  config.after do
    DatabaseCleaner.clean
  end
end
