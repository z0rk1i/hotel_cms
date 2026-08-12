require "rails_helper"

RSpec.describe RoomStatusLog, type: :model do
  describe ".record!" do
    it "creates a journal entry with from/to statuses" do
      room = create(:room)

      RoomStatusLog.record!(room: room, from: "available", to: "occupied")

      log = RoomStatusLog.last
      expect(log.room).to eq(room)
      expect(log.from_status).to eq("available")
      expect(log.to_status).to eq("occupied")
    end
  end

  describe ".ordered" do
    it "sorts by newest first" do
      room = create(:room)
      first = RoomStatusLog.record!(room: room, from: "available", to: "occupied")
      second = RoomStatusLog.record!(room: room, from: "occupied", to: "cleaning")

      expect(room.status_logs.ordered).to eq([ second, first ])
    end
  end
end
