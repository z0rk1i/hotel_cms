require "rails_helper"

RSpec.describe AdminMailer, type: :mailer do
  let(:admin) { create(:administrator) }

  describe "#new_booking" do
    let(:user) { create(:user, full_name: "Иван Петров", email: "guest@example.org") }
    let(:booking) do
      create(:booking, user: user, check_in: Date.current + 2, check_out: Date.current + 4, guests_count: 1)
    end
    let(:mail) { described_class.new_booking(booking) }

    before { admin }

    it "sends to all administrators" do
      expect(mail.to).to eq([ admin.email ])
      expect(mail.subject).to eq("Новая бронь №#{booking.id} — требуется подтверждение")
    end

    it "renders booking details and a link to the admin page" do
      expect(mail.text_part.body.decoded).to include(booking.guest.full_name)
      expect(mail.text_part.body.decoded).to include("№#{booking.room.number}")
      expect(mail.html_part.body.decoded).to include(admin_booking_url(booking))
    end
  end

  describe "#new_review" do
    let(:user) { create(:user) }
    let(:room) { create(:room) }
    let(:review) do
      give_user_a_stay!(user, room)
      create(:review, user: user, reviewable: room, rating: 5, body: "Отличный номер")
    end
    let(:mail) { described_class.new_review(review) }

    before { admin }

    it "sends to all administrators" do
      expect(mail.to).to eq([ admin.email ])
      expect(mail.subject).to eq("Новый отзыв ожидает модерации")
    end

    it "renders the review details and a link to moderation" do
      expect(mail.text_part.body.decoded).to include(user.full_name)
      expect(mail.text_part.body.decoded).to include("Отличный номер")
      expect(mail.html_part.body.decoded).to include(admin_reviews_url)
    end
  end

  describe "delivery hooks", type: :model do
    it "enqueues an admin email when a booking is created and administrators exist" do
      admin
      expect do
        create(:booking)
      end.to change(enqueued_jobs, :count).by(1)
    end

    it "does not enqueue an admin email when there are no administrators" do
      expect do
        create(:booking)
      end.not_to change(enqueued_jobs, :count)
    end

    it "enqueues an admin email when a review is created and administrators exist" do
      admin
      user = create(:user)
      room = create(:room)
      give_user_a_stay!(user, room)

      expect do
        create(:review, user: user, reviewable: room)
      end.to change(enqueued_jobs, :count).by(1)
    end
  end
end
