module RoutesHelper
  def path_with(path, query = {})
    parts = query.reject { |_, v| v.nil? || v == "" || v == [] || v == [ "" ] }
    anchor = parts.delete(:anchor)
    qs = parts.map { |k, v| "#{Rack::Utils.escape(k.to_s)}=#{Rack::Utils.escape(Array(v).join(","))}" }.join("&")
    result = qs.empty? ? path : "#{path}?#{qs}"
    anchor.present? ? "#{result}##{anchor}" : result
  end

  def root_path(query = {})
    path_with("/", query)
  end

  def gallery_path = "/gallery"
  def news_path = "/news"
  def news_article_path(slug) = "/news/#{slug}"
  def page_path(slug) = "/page/#{slug}"
  def privacy_policy_path = "/privacy"
  def room_path(room) = "/rooms/#{id_of(room)}"
  def new_booking_path(query = {}) = path_with("/bookings/new", query)
  def bookings_path = "/bookings"
  def bookings_available_rooms_path = "/bookings/available_rooms"
  def account_path(query = {}) = path_with("/account", query)
  def account_find_path = "/account/find"

  def admin_root_path = "/admin"
  def admin_rooms_path(query = {}) = path_with("/admin/rooms", query)
  def new_admin_room_path = "/admin/rooms/new"
  def admin_room_path(room) = "/admin/rooms/#{id_of(room)}"
  def edit_admin_room_path(room) = "#{admin_room_path(room)}/edit"
  def admin_room_photo_path(room, photo) = "#{admin_room_path(room)}/photo/#{id_of(photo)}"
  def complete_cleaning_admin_room_path(room) = "#{admin_room_path(room)}/complete_cleaning"

  def admin_stays_path(query = {}) = path_with("/admin/stays", query)
  def admin_stay_path(stay) = "/admin/stays/#{id_of(stay)}"
  def edit_admin_stay_path(stay) = "#{admin_stay_path(stay)}/edit"
  def new_admin_stay_path(query = {}) = path_with("/admin/stays/new", query)
  def confirm_admin_stay_path(stay) = "#{admin_stay_path(stay)}/confirm"
  def check_in_admin_stay_path(stay) = "#{admin_stay_path(stay)}/check_in"
  def check_out_admin_stay_path(stay) = "#{admin_stay_path(stay)}/check_out"
  def cancel_admin_stay_path(stay) = "#{admin_stay_path(stay)}/cancel"
  def add_payment_admin_stay_path(stay) = "#{admin_stay_path(stay)}/add_payment"
  def remove_payment_admin_stay_path(stay, payment_id:) = "#{admin_stay_path(stay)}/remove_payment/#{payment_id}"
  def add_service_admin_stay_path(stay) = "#{admin_stay_path(stay)}/add_service"
  def cancel_service_admin_stay_path(stay, service_id:) = "#{admin_stay_path(stay)}/cancel_service/#{service_id}"

  def admin_users_path(query = {}) = path_with("/admin/users", query)
  def admin_user_path(user) = "/admin/users/#{id_of(user)}"
  def merge_into_admin_user_path(user) = "#{admin_user_path(user)}/merge_into"
  def toggle_vip_admin_user_path(user) = "#{admin_user_path(user)}/toggle_vip"

  def admin_reports_path(query = {}) = path_with("/admin/reports", query)

  def new_user_session_path = "/admin/users/sign_in"
  def destroy_user_session_path = "/admin/users/sign_out"

  private

  def id_of(record)
    record.respond_to?(:id) ? record.id : record
  end
end
