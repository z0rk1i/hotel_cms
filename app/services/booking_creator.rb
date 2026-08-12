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
    user.valid? && guest.valid? && booking.valid? && check_in_not_in_past(booking)
  end

  def check_in_not_in_past(booking)
    return true if booking.check_in.blank? || booking.check_in >= Date.current

    booking.errors.add(:check_in, "не может быть в прошлом")
    false
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
