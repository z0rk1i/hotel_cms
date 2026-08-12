class BookingCreator
  include Dry::Monads[:result]

  Result = Struct.new(:user, :guest, :booking, keyword_init: true)

  def call(current_user:, booking_attrs:, user_attrs: {})
    user = current_user || User.new(user_attrs)
    guest = find_or_build_guest(user)
    booking = Booking.new(booking_attrs.merge(user: user, guest: guest, status: :pending))

    return Failure(Result.new(user: user, guest: guest, booking: booking)) unless valid?(user, guest, booking)

    persist_all(user, guest, booking)
  end

  private

  def valid?(user, guest, booking)
    user.valid? && guest.valid? && booking.valid? && check_in_not_in_past(booking) && stay_supported?(booking)
  end

  def check_in_not_in_past(booking)
    return true if booking.check_in.blank? || booking.check_in >= Date.current

    booking.errors.add(:check_in, "не может быть в прошлом")
    false
  end

  def stay_supported?(booking)
    return true if booking.check_in.blank? || booking.check_out.blank?

    before = booking.errors.size

    closed = StayRules.closed_dates_between(check_in: booking.check_in, check_out: booking.check_out)
    booking.errors.add(:check_in, "— отель закрыт на выбранные даты") if closed.any?

    min_nights = StayRules.min_nights_between(check_in: booking.check_in, check_out: booking.check_out)
    if min_nights > (booking.check_out - booking.check_in)
      booking.errors.add(:check_out, "— минимальный срок проживания составляет #{min_nights} #{StayRules.nights_word(min_nights)}")
    end

    booking.errors.size == before
  end

  def find_or_build_guest(user)
    guest = Guest.find_or_initialize_by(email: user.email)
    guest.full_name = user.full_name if guest.full_name.blank?
    guest.phone = user.phone if guest.phone.blank?
    guest
  end

  def persist_all(user, guest, booking)
    ActiveRecord::Base.transaction do
      user.save!
      guest.save!
      booking.save!
    end

    Success(Result.new(user: user, guest: guest, booking: booking))
  rescue ActiveRecord::RecordInvalid
    Failure(Result.new(user: user, guest: guest, booking: booking))
  end
end
