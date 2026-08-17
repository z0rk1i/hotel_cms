require_relative "config/environment"
require_relative "app/app_base"
require_relative "app/controllers/admin/auth_routes"
require_relative "app/controllers/admin/dashboard_routes"
require_relative "app/controllers/admin/rooms_routes"
require_relative "app/controllers/admin/stays_routes"
require_relative "app/controllers/admin/users_routes"
require_relative "app/controllers/admin/reports_routes"

class AdminApp < AppBase
  helpers AdminHelper

  register Admin::AuthRoutes, Admin::DashboardRoutes, Admin::RoomsRoutes,
          Admin::StaysRoutes, Admin::UsersRoutes, Admin::ReportsRoutes

  before do
    require_admin! unless request.path_info.match?(%r{\A/users/sign_(in|out)\z})
  end
end
