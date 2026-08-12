module StayHelpers
  # Creates a completed (checked_out) past stay for the user in the room,
  # with a date range unique per user to avoid overlap conflicts.
  def create_room_stay(user, room)
    offset = (user.id || 0) * 5
    create(:booking, :checked_out, user: user, room: room,
           check_in: Date.current - (12 + offset), check_out: Date.current - (10 + offset))
  end

  # Creates a confirmed service order for the user tied to an active booking.
  def create_service_stay(user, service)
    booking = create(:booking, :confirmed, user: user,
                     check_in: Date.current + 1, check_out: Date.current + 5)
    create(:service_order, :confirmed, user: user, booking: booking,
           service: service, service_date: Date.current + 3)
  end

  def give_user_a_stay!(user, reviewable)
    case reviewable
    when Room then create_room_stay(user, reviewable)
    when Service then create_service_stay(user, reviewable)
    end
  end
end
