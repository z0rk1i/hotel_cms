class RoomStatusLog < ApplicationRecord
  belongs_to :room

  scope :ordered, -> { order(created_at: :desc) }

  def self.record!(room:, from:, to:)
    create!(room: room, from_status: from, to_status: to)
  end
end
