module RoomStatusSync
  extend ActiveSupport::Concern

  included do
    after_save :sync_room_status, if: -> { saved_change_to_status? }
    before_destroy :free_room, if: -> { checked_in? }
  end

  private

  def sync_room_status
    if checked_in?
      room.update_column(:status, :occupied) unless room.occupied?
    elsif status_before_last_save == "checked_in"
      room.update_column(:status, :available) if room.occupied?
    end
  end

  def free_room
    room.update_column(:status, :available) if room.occupied?
  end
end
