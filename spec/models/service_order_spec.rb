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
end
