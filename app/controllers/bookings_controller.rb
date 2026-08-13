class BookingsController < ApplicationController
  def new
    @room = Room.find(params[:room_id]) if params[:room_id].present?
    @from = params[:check_in]
    @to = params[:check_out]
    @guests = params[:guests_count].presence || 1
  end

  def available_rooms
    from = Date.parse(params[:check_in])
    to = Date.parse(params[:check_out])
    guests = params[:guests_count].to_i

    rooms = Room.order(:number).select do |room|
      room.capacity >= guests && room.bookable? && room.available_on?(from, to)
    end

    render json: rooms.map { |room| room_summary(room, from, to) }
  rescue Date::Error
    render json: { error: "Неверный формат дат" }, status: :unprocessable_entity
  end

  def create
    from = Date.parse(params[:check_in])
    to = Date.parse(params[:check_out])
    room = Room.find(params[:room_id])
    user = find_or_create_guest

    @stay = Stay.new(room: room, user: user, check_in: from, check_out: to,
                     guests_count: params[:guests_count].to_i, notes: params[:notes])
    errors = collect_errors(from, to, room, user)

    if errors.empty? && @stay.valid?
      Stay.transaction do
        user.save!
        user.confirm_consent!
        @stay.save!
      end
      BookingMailer.confirmation(@stay).deliver_later if user.email.present?
      redirect_to account_path(phone: user.phone.to_s),
                  notice: "Заявка принята! Менеджер подтвердит её в ближайшее время."
    else
      @room = room
      @from = params[:check_in]
      @to = params[:check_out]
      @guests = params[:guests_count]
      @errors = errors + user.errors.full_messages
      render :new, status: :unprocessable_entity
    end
  rescue Date::Error
    @errors = [ "Неверный формат дат" ]
    render :new, status: :unprocessable_entity
  end

  private

  def collect_errors(from, to, room, user)
    errors = []
    errors << "Необходимо согласие на обработку персональных данных" if params[:consent].blank?
    errors << "Дата заезда не может быть в прошлом" if from < Date.current
    errors << "Номер уже занят на выбранные даты" unless room.available_on?(from, to)
    errors << @stay.errors.full_messages.to_sentence unless @stay.valid?
    errors
  end

  def find_or_create_guest
    phone = params[:phone].to_s.strip
    user = User.guests.find_by(phone: phone) if phone.present?
    user || User.new(role: :guest, full_name: params[:full_name], phone: phone, email: params[:email].presence)
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
end
