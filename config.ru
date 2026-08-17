require_relative "config/environment"
require_relative "app"
require_relative "admin"

map "/admin" do
  run AdminApp
end

map "/" do
  run App
end
