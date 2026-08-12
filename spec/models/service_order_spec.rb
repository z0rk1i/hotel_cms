require "rails_helper"

RSpec.describe ServiceOrder, type: :model do
  it "is valid with valid attributes" do
    expect(build(:service_order)).to be_valid
  end

  it "requires a service and a user" do
    expect(build(:service_order, service: nil)).to be_invalid
    expect(build(:service_order, user: nil)).to be_invalid
  end

  it "requires a service date" do
    expect(build(:service_order, service_date: nil)).to be_invalid
  end

  it "rejects a service date in the past" do
    expect(build(:service_order, service_date: Date.current - 1)).to be_invalid
    expect(build(:service_order, service_date: Date.current)).to be_valid
  end

  it "requires a booking" do
    expect(build(:service_order, booking: nil, with_booking: false)).to be_invalid
  end

  it "rejects a booking that does not belong to the user" do
    other_booking = create(:booking, :confirmed, user: create(:user))
    order = build(:service_order, booking: other_booking)
    expect(order).to be_invalid
    expect(order.errors[:booking]).to include("не принадлежит пользователю")
  end

  it "rejects a pending booking" do
    user = create(:user)
    booking = create(:booking, :pending, user: user, check_in: Date.current + 1, check_out: Date.current + 5)
    order = build(:service_order, user: user, booking: booking)
    expect(order).to be_invalid
    expect(order.errors[:booking]).to be_present
  end

  it "rejects a cancelled booking" do
    user = create(:user)
    booking = create(:booking, :cancelled, user: user, check_in: Date.current + 1, check_out: Date.current + 5)
    order = build(:service_order, user: user, booking: booking)
    expect(order).to be_invalid
    expect(order.errors[:booking]).to be_present
  end

  it "accepts a checked_in booking" do
    user = create(:user)
    booking = create(:booking, :checked_in, user: user, check_in: Date.current - 1, check_out: Date.current + 5)
    expect(build(:service_order, user: user, booking: booking)).to be_valid
  end

  it "rejects a service date outside the booking period" do
    user = create(:user)
    booking = create(:booking, :confirmed, user: user, check_in: Date.current + 1, check_out: Date.current + 5)
    order = build(:service_order, user: user, booking: booking, service_date: Date.current + 6)
    expect(order).to be_invalid
    expect(order.errors[:service_date]).to include("должна попадать в период брони")
  end

  it "accepts a service date on the last night of the booking" do
    user = create(:user)
    booking = create(:booking, :confirmed, user: user, check_in: Date.current + 1, check_out: Date.current + 5)
    order = build(:service_order, user: user, booking: booking, service_date: Date.current + 4)
    expect(order).to be_valid
  end

  it "requires quantity of at least 1" do
    expect(build(:service_order, quantity: 0)).to be_invalid
    expect(build(:service_order, quantity: nil)).to be_invalid
  end

  it "calculates total price from service price and quantity" do
    service = create(:service, price: 500)
    order = create(:service_order, service: service, quantity: 3)
    expect(order.total_price).to eq(1500)
  end

  describe "notifications" do
    it "notifies the user when the status changes" do
      order = create(:service_order)
      expect { order.confirmed! }.to change(order.user.notifications, :count).by(1)
      notification = order.user.notifications.last
      expect(notification.notifiable).to eq(order)
      expect(notification.kind).to eq("service_order_status")
      expect(notification.title).to include("заказа услуги")
    end

    it "does not notify when the status is unchanged" do
      order = create(:service_order, notes: "Уже есть")
      expect { order.update(notes: "Обновлено") }.not_to change(Notification, :count)
    end
  end

  describe "status transitions" do
    it "allows confirming a pending order and cancelling a confirmed one" do
      order = create(:service_order)
      expect(order.transition_to(:confirmed)).to be(true)
      expect(order.transition_to(:cancelled)).to be(true)
    end

    it "rejects confirming an already cancelled order" do
      order = create(:service_order, :cancelled)
      expect(order.transition_to(:confirmed)).to be(false)
      expect(order).to be_cancelled
    end
  end
end
