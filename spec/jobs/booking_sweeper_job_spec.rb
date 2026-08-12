require "rails_helper"

RSpec.describe BookingSweeperJob, type: :job do
  describe "#perform" do
    it "checks out stays whose check_out date has passed" do
      stale = create(:booking, :checked_in, check_in: Date.current - 3, check_out: Date.current - 1)
      current = create(:booking, :checked_in, check_in: Date.current - 1, check_out: Date.current + 1)

      described_class.perform_now

      expect(stale.reload).to be_checked_out
      expect(current.reload).to be_checked_in
    end

    it "frees the room of an auto-checked-out booking" do
      booking = create(:booking, :checked_in, check_in: Date.current - 3, check_out: Date.current - 1)
      room = booking.room
      expect(room.reload).to be_occupied

      described_class.perform_now

      expect(room.reload).to be_cleaning
    end

    it "cancels pending and confirmed bookings whose check_in day has passed" do
      pending = create(:booking, :pending, check_in: Date.current - 2, check_out: Date.current + 1)
      confirmed = create(:booking, :confirmed, check_in: Date.current - 1, check_out: Date.current + 2)
      upcoming = create(:booking, :confirmed, check_in: Date.current + 1, check_out: Date.current + 3)

      described_class.perform_now

      expect(pending.reload).to be_cancelled
      expect(confirmed.reload).to be_cancelled
      expect(upcoming.reload).to be_confirmed
    end

    it "does not cancel a booking checking in today" do
      today = create(:booking, :confirmed, check_in: Date.current, check_out: Date.current + 1)

      described_class.perform_now

      expect(today.reload).to be_confirmed
    end

    it "applies a no-show fee equal to the first night's price" do
      booking = create(:booking, :confirmed, room: create(:room, price_per_night: 2000),
                                             check_in: Date.current - 1, check_out: Date.current + 2)

      described_class.perform_now

      expect(booking.reload).to be_cancelled
      expect(booking.no_show_fee).to eq(booking.nightly_prices.find_by(date: Date.current - 1).amount)
    end

    it "enqueues a reminder email for confirmed bookings checking in tomorrow" do
      user = create(:user, email: "guest@example.org")
      create(:booking, :confirmed, user: user, check_in: Date.current + 1, check_out: Date.current + 3)
      create(:booking, :confirmed, check_in: Date.current + 1, check_out: Date.current + 3)
      create(:booking, :confirmed, user: user, check_in: Date.current + 5, check_out: Date.current + 7)

      expect { described_class.perform_now }
        .to change { ActiveJob::Base.queue_adapter.enqueued_jobs.count { |j| j[:job] == ActionMailer::MailDeliveryJob } }
        .by(1)
    end

    it "does not enqueue reminders for bookings without a deliverable email" do
      create(:booking, :confirmed, check_in: Date.current + 1, check_out: Date.current + 3)

      expect { described_class.perform_now }.not_to change(ActiveJob::Base.queue_adapter.enqueued_jobs, :count)
    end
  end
end
