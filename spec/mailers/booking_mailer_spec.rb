require "rails_helper"

RSpec.describe BookingMailer, type: :mailer do
  let(:user) { create(:user, full_name: "Иван Петров", email: "guest@example.org") }
  let(:stay) do
    create(:stay, user: user, check_in: Date.current + 2, check_out: Date.current + 4, guests_count: 1)
  end

  describe "#confirmation" do
    let(:mail) { described_class.confirmation(stay) }

    it "sends to the user's email with a Russian subject" do
      expect(mail.to).to eq([ user.email ])
      expect(mail.subject).to eq("Бронь №#{stay.id} создана — ожидает подтверждения")
    end

    it "renders stay details in HTML and text" do
      expect(mail.text_part.body.decoded).to include("Номер: #{stay.room.number}")
      expect(mail.html_part.body.decoded).to include(stay.room.number.to_s)
      expect(mail.html_part.body.decoded).to include("Иван Петров")
    end

    it "links to the personal account" do
      expect(mail.html_part.body.decoded).to include(account_url)
    end
  end
end
