# Protect the public forms (bookings, reviews, service orders) from request
# flooding: at most 10 mutating requests per minute per IP. Admin paths and
# read requests are excluded. The counter is database-backed so it works
# with any Rails.cache store (memory/null stores lack #increment).
require_relative "../../app/services/rate_limit_counter"

Rails.application.config.middleware.use Rack::Ratelimit, {
  name: "public_forms",
  rate: [ 10, 60 ],
  counter: RateLimitCounter.new("public_forms"),
  exceptions: [
    ->(env) { %w[GET HEAD OPTIONS].include?(env["REQUEST_METHOD"]) },
    ->(env) { env["PATH_INFO"].to_s.start_with?("/admin") }
  ],
  logger: Rails.logger
} do |env|
  (env["action_dispatch.remote_ip"] || Rack::Request.new(env).ip).to_s
end
