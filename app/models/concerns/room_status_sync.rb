module RoomStatusSync
  extend ActiveSupport::Concern

  included do
    after_save :sync_room_status, if: -> { saved_change_to_status? }
    before_destroy :free_room, if: -> { checked_in? }
  end

  private

  def sync_room_status
    if checked_in?
      record_room_status(:occupied)
    elsif status_before_last_save == "checked_in"
      if other_checked_in_bookings?
        record_room_status(:occupied)
      else
        record_room_status(checked_out? ? :cleaning : :available)
      end
    end
  end

  def free_room
    return unless room.occupied?
    return if other_checked_in_bookings?

    record_room_status(:available)
  end

  def other_checked_in_bookings?
    room.bookings.checked_in_now.where.not(id: id).exists?
  end

  def record_room_status(to)
    return if room.status.to_s == to.to_s

    from = room.status
    room.update_column(:status, to)
    RoomStatusLog.record!(room: room, from: from, to: to.to_s)
  end
end
