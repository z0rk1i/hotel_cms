require "rails_helper"

RSpec.describe "Public form rate limiting", type: :request do
  include ActiveSupport::Testing::TimeHelpers

  let(:room) { create(:room) }

  def booking_params(email)
    {
      booking: { room_id: room.id, check_in: Date.current + 3, check_out: Date.current + 5, guests_count: 1 },
      user: { full_name: "Тест", email: email, phone: "+7 900 000-00-00", password: "password123" }
    }
  end

  it "blocks the 11th mutating request with 429" do
    10.times do |i|
      post bookings_path, params: booking_params("guest#{i}@example.com")
      expect(response).not_to have_http_status(:too_many_requests)
    end

    post bookings_path, params: booking_params("overflow@example.com")
    expect(response).to have_http_status(:too_many_requests)
    expect(response.headers["Retry-After"]).to be_present
  end

  it "does not rate-limit read requests" do
    get root_path
    get root_path
    get root_path
    expect(response).to have_http_status(:ok)
  end

  it "does not rate-limit admin requests" do
    sign_in create(:administrator)

    11.times do
      get admin_root_path
      expect(response).not_to have_http_status(:too_many_requests)
    end
  end

  it "resets the counter after a new time window" do
    now = Time.now

    travel_to now do
      10.times do |i|
        post bookings_path, params: booking_params("guest#{i}@example.com")
      end
      post bookings_path, params: booking_params("overflow@example.com")
      expect(response).to have_http_status(:too_many_requests)
    end

    travel_to now + 61.seconds do
      post bookings_path, params: booking_params("fresh@example.com")
      expect(response).not_to have_http_status(:too_many_requests)
    end
  end
end
