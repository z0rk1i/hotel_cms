require_relative "config/environment"
require "sinatra/base"
require "csv"

class AdminApp < Sinatra::Base
  set :root, APP_ROOT
  set :views, File.join(APP_ROOT, "app", "views")
  set :public_folder, File.join(APP_ROOT, "public")
  set :show_exceptions, false
  set :haml, escape_html: false
  set :raise_errors, ENV["APP_ENV"] == "test"
  set :session_secret, ENV.fetch("SESSION_SECRET", "dev-secret-hotel-cms-change-me-in-production-00000000000000000000000000")
  require "ipaddr"
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

  helpers ApplicationHelper, AdminHelper, RoutesHelper, AppSupport

  before do
    @flash = session.delete("flash") || {}
    protect_from_forgery
    require_admin! unless request.path_info.match?(%r{\A/users/sign_(in|out)\z})
  end

  # ---- Auth ----
  get "/users/sign_in" do
    redirect admin_root_path if current_user&.admin?
    haml :"users/sessions/new", layout: :auth
  end

  post "/users/sign_in" do
    user = User.find_by(email: params["email"].to_s.strip.downcase)
    if user&.valid_password?(params["password"].to_s)
      session["user_id"] = user.id
      redirect user.admin? ? admin_root_path : root_path
    else
      session["flash"] = { "alert" => "Неверный email или пароль" }
      redirect new_user_session_path
    end
  end

  post "/users/sign_out" do
    session.clear
    redirect new_user_session_path
  end

  delete "/users/sign_out" do
    session.clear
    redirect new_user_session_path
  end

  # ---- Dashboard ----
  get "/" do
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

  # ---- Rooms ----
  get "/rooms" do
    @rooms = Room.order(:floor, :number)
    @rooms = @rooms.by_status(params["status"].downcase) if params["status"].present?
    @rooms = @rooms.search(params["query"]) if params["query"].present?
    haml :"admin/rooms/index", layout: :admin
  end

  get "/rooms/new" do
    @room = Room.new(status: :available)
    haml :"admin/rooms/new", layout: :admin
  end

  post "/rooms" do
    @room = Room.new(room_params)
    if @room.save
      attach_uploaded_photos(@room)
      session["flash"] = { "notice" => "Номер добавлен" }
      redirect admin_rooms_path
    else
      status 422
      haml :"admin/rooms/new", layout: :admin
    end
  end

  get "/rooms/:id/edit" do
    @room = Room.find(params["id"])
    haml :"admin/rooms/edit", layout: :admin
  end

  patch "/rooms/:id" do
    @room = Room.find(params["id"])
    if @room.update(room_params)
      attach_uploaded_photos(@room)
      session["flash"] = { "notice" => "Номер обновлён" }
      redirect admin_rooms_path
    else
      status 422
      haml :"admin/rooms/edit", layout: :admin
    end
  end

  delete "/rooms/:id" do
    @room = Room.find(params["id"])
    if @room.destroy
      session["flash"] = { "notice" => "Номер удалён" }
    else
      session["flash"] = { "alert" => @room.errors.full_messages.to_sentence }
    end
    redirect admin_rooms_path
  end

  patch "/rooms/:id/complete_cleaning" do
    @room = Room.find(params["id"])
    @room.update!(status: :available)
    session["flash"] = { "notice" => "Уборка завершена, номер доступен" }
    redirect admin_rooms_path
  end

  delete "/rooms/:id/photo/:photo_id" do
    @room = Room.find(params["id"])
    photo = @room.photos.find(params["photo_id"])
    photo.destroy_with_files!
    session["flash"] = { "notice" => "Фотография удалена" }
    redirect edit_admin_room_path(@room)
  rescue ActiveRecord::RecordNotFound
    session["flash"] = { "alert" => "Фотография не найдена" }
    redirect edit_admin_room_path(@room)
  end

  # ---- Stays ----
  get "/stays" do
    @stays = Stay.order(check_in: :desc)
    if params["status"].in?(%w[pending confirmed checked_in checked_out cancelled])
      @stays = @stays.public_send(params["status"])
    end
    @stays = @stays.where("check_in >= ?", Date.parse(params["from"])) if params["from"].present?
    @stays = @stays.where("check_out <= ?", Date.parse(params["to"])) if params["to"].present?
    if params["query"].present?
      q = "%#{params['query']}%"
      @stays = @stays.joins(:user).where("users.full_name ILIKE ? OR users.phone ILIKE ?", q, q)
    end
    haml :"admin/stays/index", layout: :admin
  rescue Date::Error
    session["flash"] = { "alert" => "Неверный формат дат" }
    redirect admin_stays_path
  end

  get "/stays/new" do
    @stay = Stay.new(check_in: Date.current + 1, check_out: Date.current + 2, guests_count: 1, status: :pending)
    haml :"admin/stays/new", layout: :admin
  end

  post "/stays" do
    @stay = Stay.new(stay_params)
    if @stay.save
      session["flash"] = { "notice" => "Бронь создана" }
      redirect admin_stay_path(@stay)
    else
      status 422
      haml :"admin/stays/new", layout: :admin
    end
  end

  get "/stays/:id" do
    @stay = Stay.includes(:room, :user).find(params["id"])
    haml :"admin/stays/show", layout: :admin
  end

  get "/stays/:id/edit" do
    @stay = Stay.includes(:room, :user).find(params["id"])
    haml :"admin/stays/edit", layout: :admin
  end

  patch "/stays/:id" do
    @stay = Stay.includes(:room, :user).find(params["id"])
    if @stay.update(stay_params)
      session["flash"] = { "notice" => "Бронь обновлена" }
      redirect admin_stay_path(@stay)
    else
      status 422
      haml :"admin/stays/edit", layout: :admin
    end
  end

  delete "/stays/:id" do
    @stay = Stay.find(params["id"])
    @stay.destroy!
    session["flash"] = { "notice" => "Бронь удалена" }
    redirect admin_stays_path
  rescue ActiveRecord::RecordNotDestroyed
    session["flash"] = { "alert" => "Не удалось удалить бронь" }
    redirect admin_stays_path
  end

  patch "/stays/:id/confirm" do
    transition { @stay.transition_to!("confirmed") }
  end

  patch "/stays/:id/check_in" do
    transition { @stay.transition_to!("checked_in") }
  end

  patch "/stays/:id/check_out" do
    transition { @stay.transition_to!("checked_out") }
  end

  patch "/stays/:id/cancel" do
    transition { @stay.transition_to!("cancelled") }
  end

  post "/stays/:id/add_payment" do
    @stay = Stay.find(params["id"])
    @stay.add_payment!(method: params["method"], amount: params["amount"],
                       paid_at: parse_date_or_now(params["paid_at"]), note: params["note"])
    session["flash"] = { "notice" => "Оплата добавлена" }
    redirect admin_stay_path(@stay)
  rescue ArgumentError => e
    session["flash"] = { "alert" => e.message }
    redirect admin_stay_path(@stay)
  end

  delete "/stays/:id/remove_payment/:payment_id" do
    @stay = Stay.find(params["id"])
    @stay.remove_payment!(params["payment_id"])
    session["flash"] = { "notice" => "Оплата удалена" }
    redirect admin_stay_path(@stay)
  end

  post "/stays/:id/add_service" do
    @stay = Stay.find(params["id"])
    @stay.add_service!(name: params["name"], price: params["price"],
                       quantity: params["quantity"], date: parse_date_or_today(params["date"]),
                       note: params["note"])
    session["flash"] = { "notice" => "Услуга добавлена" }
    redirect admin_stay_path(@stay)
  rescue ArgumentError => e
    session["flash"] = { "alert" => e.message }
    redirect admin_stay_path(@stay)
  end

  delete "/stays/:id/cancel_service/:service_id" do
    @stay = Stay.find(params["id"])
    @stay.cancel_service!(params["service_id"])
    session["flash"] = { "notice" => "Услуга отменена" }
    redirect admin_stay_path(@stay)
  end

  # ---- Users ----
  get "/users" do
    @users = User.order(:role, :full_name)
    @users = @users.guests if params["type"] == "guests"
    @users = @users.where(is_vip: true) if params["vip"].present?
    @users = @users.search(params["query"]) if params["query"].present?
    haml :"admin/users/index", layout: :admin
  end

  get "/users/:id" do
    @user = User.find(params["id"])
    @stays = @user.stays.order(check_in: :desc)
    haml :"admin/users/show", layout: :admin
  end

  delete "/users/:id" do
    @user = User.find(params["id"])
    if @user.destroy
      session["flash"] = { "notice" => "Пользователь удалён" }
    else
      session["flash"] = { "alert" => @user.errors.full_messages.to_sentence }
    end
    redirect admin_users_path
  end

  post "/users/:id/toggle_vip" do
    @user = User.find(params["id"])
    @user.update!(is_vip: !@user.is_vip)
    session["flash"] = { "notice" => @user.is_vip ? "VIP" : "Не VIP" }
    redirect admin_user_path(@user)
  end

  patch "/users/:id/toggle_vip" do
    @user = User.find(params["id"])
    @user.update!(is_vip: !@user.is_vip)
    session["flash"] = { "notice" => @user.is_vip ? "VIP" : "Не VIP" }
    redirect admin_user_path(@user)
  end

  post "/users/:id/merge_into" do
    @user = User.find(params["id"])
    target = User.find(params["target_user_id"])
    @user.merge_into!(target)
    session["flash"] = { "notice" => "Профили объединены" }
    redirect admin_user_path(target)
  rescue ActiveRecord::RecordNotFound
    session["flash"] = { "alert" => "Пользователь не найден" }
    redirect admin_user_path(@user)
  end

  # ---- Reports ----
  get "/reports" do
    @from = parse_date("from") || Date.current.beginning_of_month
    @to = parse_date("to") || Date.current.end_of_month
    @from, @to = @to, @from if @from > @to
    @report = Report.refresh!(from: @from, to: @to)

    if params["format"] == "csv"
      content_type "text/csv"
      headers "Content-Disposition" => %(attachment; filename="report_#{@from.iso8601}_#{@to.iso8601}.csv")
      body build_report_csv
    else
      haml :"admin/reports/show", layout: :admin
    end
  end

  not_found do
    File.read(File.join(APP_ROOT, "public", "404.html"))
  end

  error ActiveRecord::RecordNotFound do
    File.read(File.join(APP_ROOT, "public", "404.html"))
  end

  error do
    status 500
    File.read(File.join(APP_ROOT, "public", "500.html"))
  end

  private

  def transition
    @stay = Stay.find(params["id"])
    yield
    session["flash"] = { "notice" => "Статус обновлён" }
    redirect admin_stay_path(@stay)
  rescue ArgumentError, ActiveRecord::RecordInvalid => e
    session["flash"] = { "alert" => e.message }
    redirect admin_stay_path(@stay)
  end

  def parse_date_or_now(value)
    value.present? ? Date.parse(value).to_time : Time.current
  rescue Date::Error
    Time.current
  end

  def parse_date_or_today(value)
    value.present? ? Date.parse(value) : Date.current
  rescue Date::Error
    Date.current
  end

  def parse_date(key)
    value = params[key]
    return nil if value.blank?

    Date.parse(value)
  rescue ArgumentError, TypeError
    nil
  end

  def room_params
    permitted = %i[number category floor capacity size_sqm description
                   price_per_night weekend_multiplier min_nights status
                   unavailable_from unavailable_until]
    result = {}
    permitted.each do |key|
      result[key] = params["room"]&.[](key.to_s) if params["room"]&.key?(key.to_s)
    end
    result[:amenities] = Array(params["room"]&.[]("amenities")).reject { |v| v == "" }
    result
  end

  def stay_params
    permitted = %i[room_id user_id check_in check_out guests_count status total_price notes]
    result = {}
    permitted.each do |key|
      result[key] = params["stay"]&.[](key.to_s) if params["stay"]&.key?(key.to_s)
    end
    result
  end

  def attach_uploaded_photos(room)
    files = params["photos"]
    return if files.blank?

    files = [ files ] unless files.is_a?(Array)
    files.each_with_index do |file, idx|
      next unless file.respond_to?(:tempfile) && file[:tempfile] && file[:tempfile].size.positive?

      RoomPhoto.attach_file(room, file[:tempfile].path, file[:filename], position: room.photos.count + idx + 1)
    end
  end

  def build_report_csv
    headers = [ "Дата", "По тарифу (план), ₽", "Принято (факт), ₽" ]
    rows = @report.nightly.map do |date, values|
      [ date, values.fetch("plan", 0), values.fetch("fact", 0) ]
    end
    rows.unshift([ "Итого", @report.plan_revenue, @report.fact_revenue ])
    CSV.generate(headers: headers, write_headers: true) { |csv| rows.each { |row| csv << row } }
  end
end
