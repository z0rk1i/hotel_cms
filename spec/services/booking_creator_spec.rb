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

    it "rejects a booking that overlaps a closed date" do
      create(:closed_date, date: Date.current + 4)

      result = described_class.new.call(
        current_user: nil,
        booking_attrs: {
          room_id: room.id,
          check_in: Date.current + 3,
          check_out: Date.current + 5,
          guests_count: 1
        },
        user_attrs: {
          full_name: "Закрыто",
          email: "closed@example.com",
          phone: "+7 900 333-33-33",
          password: "password123"
        }
      )

      expect(result).to be_failure
      expect(result.failure.booking.errors[:check_in]).to include("— отель закрыт на выбранные даты")
      expect(Booking).not_to exist
    end

    it "rejects a booking shorter than the period minimum" do
      create(:price_period, starts_on: Date.current + 3, ends_on: Date.current + 9, min_nights: 3)

      result = described_class.new.call(
        current_user: nil,
        booking_attrs: {
          room_id: room.id,
          check_in: Date.current + 3,
          check_out: Date.current + 5,
          guests_count: 1
        },
        user_attrs: {
          full_name: "Коротко",
          email: "short@example.com",
          phone: "+7 900 444-44-44",
          password: "password123"
        }
      )

      expect(result).to be_failure
      expect(result.failure.booking.errors[:check_out]).to include("— минимальный срок проживания составляет 3 ночи")
      expect(Booking).not_to exist
    end

    it "accepts a booking that meets the period minimum" do
      create(:price_period, starts_on: Date.current + 3, ends_on: Date.current + 9, min_nights: 3)

      result = described_class.new.call(
        current_user: nil,
        booking_attrs: {
          room_id: room.id,
          check_in: Date.current + 3,
          check_out: Date.current + 7,
          guests_count: 1
        },
        user_attrs: {
          full_name: "Нормально",
          email: "long@example.com",
          phone: "+7 900 555-55-55",
          password: "password123"
        }
      )

      expect(result).to be_success
    end
  end
end
