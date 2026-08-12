require "rails_helper"

RSpec.describe BookingCreator do
  describe "#call" do
    let(:room) { create(:room) }

    it "creates a user, guest and pending booking" do
      result = described_class.new.call(
        current_user: nil,
        booking_attrs: {
          room_id: room.id,
          check_in: Date.current + 3,
          check_out: Date.current + 5,
          guests_count: 1
        },
        user_attrs: {
          full_name: "Иванов Иван",
          email: "ivan@example.com",
          phone: "+7 900 000-00-00",
          password: "password123"
        }
      )

      expect(result).to be_success
      booking = result.value!.booking
      expect(booking).to be_pending
      expect(booking.user.email).to eq("ivan@example.com")
    end

    it "rejects a booking with check_in in the past" do
      result = described_class.new.call(
        current_user: nil,
        booking_attrs: {
          room_id: room.id,
          check_in: Date.current - 1,
          check_out: Date.current + 1,
          guests_count: 1
        },
        user_attrs: {
          full_name: "Поздно",
          email: "late@example.com",
          phone: "+7 900 111-11-11",
          password: "password123"
        }
      )

      expect(result).to be_failure
      expect(result.failure.booking.errors[:check_in]).to include("не может быть в прошлом")
      expect(Booking).not_to exist
    end

    it "allows check-in today" do
      result = described_class.new.call(
        current_user: nil,
        booking_attrs: {
          room_id: room.id,
          check_in: Date.current,
          check_out: Date.current + 2,
          guests_count: 1
        },
        user_attrs: {
          full_name: "Сегодня",
          email: "today@example.com",
          phone: "+7 900 222-22-22",
          password: "password123"
        }
      )

      expect(result).to be_success
    end
  end
end
