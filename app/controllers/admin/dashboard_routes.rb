module Admin
  module DashboardRoutes
    def self.registered(app)
      app.get "/" do
        @today = Date.current
        @report = Report.refresh_month(Date.current)
        @rooms = Room.order(:number)
        @occupied_rooms = @rooms.select(&:occupied_now?)
        @available_rooms = @rooms.by_status(:available)
        @maintenance_rooms = @rooms.by_status(:maintenance)
        @cleaning_rooms = @rooms.by_status(:cleaning)
        @today_check_ins = Stay.confirmed.where(check_in: @today).order(:check_out)
        @today_check_outs = Stay.checked_in.where(check_out: @today).order(:check_in)
        @upcoming_check_ins = Stay.confirmed.where(check_in: (@today + 1)..(@today + 7)).order(:check_in)
        @recent_stays = Stay.order(created_at: :desc).limit(5)
        haml :"admin/dashboard/index", layout: :admin
      end
    end
  end
end
