module StayHelpers
  def create_room_stay(user, room)
    offset = (user.id || 0) * 5
    create(:stay, :checked_out, user: user, room: room,
           check_in: Date.current - (12 + offset), check_out: Date.current - (10 + offset))
  end

  def give_user_a_stay!(user, room)
    create_room_stay(user, room)
  end
end
