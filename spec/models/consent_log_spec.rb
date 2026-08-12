require "rails_helper"

RSpec.describe ConsentLog, type: :model do
  it "is valid with a guest and signed_at" do
    consent = build(:consent_log)
    expect(consent).to be_valid
  end

  it "requires signed_at" do
    consent = build(:consent_log, signed_at: nil)
    expect(consent).not_to be_valid
  end

  it "is destroyed together with the guest" do
    guest = create(:guest)
    create(:consent_log, guest: guest)

    expect { guest.destroy }.to change(ConsentLog, :count).by(-1)
  end
end
