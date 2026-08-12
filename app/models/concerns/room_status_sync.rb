module RoomStatusSync
  extend ActiveSupport::Concern

  included do
    after_save :sync_room_status, if: -> { saved_change_to_status? }
    before_destroy :free_room, if: -> { checked_in? }
  end

  private

  def sync_room_status
    if checked_in?
      record_room_status(:occupied) unless room.occupied?
    elsif status_before_last_save == "checked_in"
      record_room_status(checked_out? ? :cleaning : :available) if room.occupied?
    end
  end

  def free_room
    record_room_status(:available) if room.occupied?
  end

  def record_room_status(to)
    from = room.status
    room.update_column(:status, to)
    RoomStatusLog.record!(room: room, from: from, to: to.to_s)
  end
end
