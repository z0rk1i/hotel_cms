require "rails_helper"

RSpec.describe BookingMailer, type: :mailer do
  let(:user) { create(:user, full_name: "Иван Петров") }
  let(:booking) do
    create(:booking, user: user, check_in: Date.current + 2, check_out: Date.current + 4, guests_count: 1)
  end

  describe "#created" do
    let(:mail) { described_class.created(booking) }

    it "sends to the user's email with a Russian subject" do
      expect(mail.to).to eq([ user.email ])
      expect(mail.subject).to eq("Бронь №#{booking.id} создана — ожидает подтверждения")
    end

    it "renders booking details in HTML and text" do
      expect(mail.text_part.body.decoded).to include("№#{booking.id} создана и ожидает подтверждения")
      expect(mail.text_part.body.decoded).to include("№#{booking.room.number}")
      expect(mail.html_part.body.decoded).to include("№#{booking.room.number}")
    end

    it "links to the personal account" do
      expect(mail.html_part.body.decoded).to include(account_url)
    end
  end

  describe "#confirmed" do
    let(:mail) { described_class.confirmed(booking) }

    it "sends with a confirmation subject" do
      expect(mail.to).to eq([ user.email ])
      expect(mail.subject).to eq("Бронь №#{booking.id} подтверждена")
    end

    it "renders the confirmation message" do
      expect(mail.text_part.body.decoded).to include("подтверждена!")
      expect(mail.html_part.body.decoded).to include("подтверждена!")
    end
  end

  describe "#cancelled" do
    let(:mail) { described_class.cancelled(booking) }

    it "sends with a cancellation subject" do
      expect(mail.to).to eq([ user.email ])
      expect(mail.subject).to eq("Бронь №#{booking.id} отменена")
    end

    it "renders the cancellation message" do
      expect(mail.text_part.body.decoded).to include("отменена")
      expect(mail.html_part.body.decoded).to include("отменена")
    end
  end

  describe "#check_in_reminder" do
    let(:mail) { described_class.check_in_reminder(booking) }

    it "sends with a reminder subject" do
      expect(mail.to).to eq([ user.email ])
      expect(mail.subject).to eq("Напоминание: заезд завтра, бронь №#{booking.id}")
    end

    it "renders the check-in date" do
      expect(mail.text_part.body.decoded).to include("ваш заезд завтра")
      expect(mail.html_part.body.decoded).to include("ваш заезд завтра")
    end
  end

  describe "delivery hooks", type: :model do
    it "enqueues an email when a booking with a deliverable user email is created" do
      expect do
        create(:booking, user: create(:user, email: "guest@example.org"))
      end.to change(enqueued_jobs, :count).by(1)
    end

    it "does not enqueue an email for a booking without a user" do
      expect do
        create(:booking)
      end.not_to change(enqueued_jobs, :count)
    end

    it "does not enqueue an email for a placeholder OAuth address" do
      user = create(:user, provider: "vkontakte", uid: "123", email: "vkontakte-123@example.com")

      expect do
        create(:booking, user: user)
      end.not_to change(enqueued_jobs, :count)
    end

    it "enqueues a confirmation email when a booking becomes confirmed" do
      booking = create(:booking, :pending, user: create(:user, email: "guest@example.org"))

      expect { booking.transition_to(:confirmed) }
        .to change { enqueued_jobs.select { |j| j[:job] == ActionMailer::MailDeliveryJob }.count }
        .by(1)
    end

    it "enqueues a cancellation email when a booking becomes cancelled" do
      booking = create(:booking, :pending, user: create(:user, email: "guest@example.org"))

      expect { booking.transition_to(:cancelled) }
        .to change { enqueued_jobs.select { |j| j[:job] == ActionMailer::MailDeliveryJob }.count }
        .by(1)
    end
  end
end
