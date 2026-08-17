require_relative "config/environment"
require_relative "app/app_base"

class App < AppBase
  # ---- Public site ----
  get "/" do
    search = RoomSearch.new(params)
    @rooms = search.rooms
    @date_error = search.date_error
    @rooms_by_category = @rooms.group_by(&:category)
    @categories = ordered_categories
    @filter_categories = Room.order(:category).distinct.pluck(:category)
    @news = StaticContent.news
    @gallery_rooms = Room.joins(:photos).distinct.order(:number).limit(8)
    haml :"public_site/index", layout: :application
  end

  get "/rooms/:id" do
    @room = Room.find(params["id"])
    @reviews = @room.approved_reviews
    @free_window = @room.next_free_window
    haml :"public_site/show", layout: :application
  end

  get "/gallery" do
    @rooms = Room.joins(:photos).distinct.order(:number)
    haml :"public_site/gallery", layout: :application
  end

  get "/news" do
    @news = StaticContent.news
    haml :"public_site/news", layout: :application
  end

  get "/news/:slug" do
    @article = StaticContent.news(params["slug"])
    not_found! unless @article
    haml :"public_site/news_article", layout: :application
  end

  get "/page/:slug" do
    @entry = StaticContent.page(params["slug"])
    not_found! unless @entry
    haml :"public_site/page", layout: :application
  end

  get "/privacy" do
    @entry = StaticContent.page("privacy") || StaticContent.page("about") || {}
    haml :"public_site/page", layout: :application
  end

  # ---- Bookings ----
  get "/bookings/available_rooms" do
    content_type :json
    from = Date.parse(params["check_in"])
    to = Date.parse(params["check_out"])
    guests = params["guests_count"].to_i

    rooms = Room.available_for(from: from, to: to, guests: guests)
    rooms.map { |room| room_summary(room, from, to) }.to_json
  rescue Date::Error
    status 422
    { error: "Неверный формат дат" }.to_json
  end

  get "/bookings/new" do
    @room = Room.find(params["room_id"]) if params["room_id"].present?
    @from = params["check_in"]
    @to = params["check_out"]
    @guests = params["guests_count"].presence || 1
    haml :"bookings/new", layout: :application
  end

  post "/bookings" do
    from = Date.parse(params["check_in"])
    to = Date.parse(params["check_out"])
    room = Room.find(params["room_id"])
    user = find_or_create_guest

    @stay = Stay.new(room: room, user: user, check_in: from, check_out: to,
                     guests_count: params["guests_count"].to_i, notes: params["notes"])
    errors = collect_errors(from, to, room, user)

    if errors.empty? && @stay.valid?
      Stay.transaction do
        user.save!
        user.confirm_consent!
        @stay.save!
      end
      BookingMailer.confirmation(@stay) if user.email.present?
      session["flash"] = { "notice" => "Заявка принята! Менеджер подтвердит её в ближайшее время." }
      redirect account_path(phone: user.phone.to_s)
    else
      @room = room
      @from = params["check_in"]
      @to = params["check_out"]
      @guests = params["guests_count"]
      @errors = errors + user.errors.full_messages
      status 422
      haml :"bookings/new", layout: :application
    end
  rescue Date::Error
    @errors = [ "Неверный формат дат" ]
    status 422
    haml :"bookings/new", layout: :application
  end

  # ---- Account ----
  get "/account" do
    @phone = params["phone"].to_s.strip
    @guest = User.guests.find_by(phone: @phone) if @phone.present?
    @stays = @guest&.stays&.order(check_in: :desc) || []
    haml :"account/show", layout: :application
  end

  get "/account/find" do
    redirect account_path(phone: params["phone"].to_s.strip)
  end

  private

  def not_found!
    halt 404
  end

  def ordered_categories
    categories = @rooms.map(&:category).uniq
    return categories unless params["sort"].in?(%w[price_asc price_desc])

    key = params["sort"] == "price_desc" ? :max : :min
    grouped = @rooms.group_by(&:category)
    categories.sort_by do |name|
      prices = grouped.fetch(name, []).map(&:price_per_night)
      [ prices.any? ? prices.send(key) : 0, name ]
    end
  end

  def find_or_create_guest
    phone = params["phone"].to_s.strip
    user = User.guests.find_by(phone: phone) if phone.present?
    user || User.new(role: :guest, full_name: params["full_name"], phone: phone, email: params["email"].presence)
  end

  def room_summary(room, from, to)
    {
      id: room.id,
      number: room.number,
      category: room.category,
      capacity: room.capacity,
      amenities: room.amenities,
      price: room.price_per_night,
      total_price: room.price_for_stay(from, to),
      label: "#{room.number} · #{room.category}"
    }
  end

  def collect_errors(from, to, room, user)
    errors = []
    errors << "Необходимо согласие на обработку персональных данных" if params["consent"].blank?
    errors << "Дата заезда не может быть в прошлом" if from < Date.current
    errors << "Номер уже занят на выбранные даты" unless room.available_on?(from, to)
    errors << user.errors.full_messages.to_sentence unless user.valid?
    errors << @stay.errors.full_messages.to_sentence unless @stay.valid?
    errors
  end
end
