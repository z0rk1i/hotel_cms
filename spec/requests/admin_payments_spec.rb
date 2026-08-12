require 'rails_helper'

RSpec.describe "Admin payments", type: :request do
  before { sign_in create(:administrator) }

  let!(:booking) { create(:booking, :confirmed) }

  describe "GET new" do
    it "renders the payment form prefilled with the due amount" do
      create(:payment, booking: booking, amount: 1000)

      get new_admin_booking_payment_path(booking)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Долг:")
      expect(response.body).to include("Добавить оплату")
    end
  end

  describe "POST create" do
    it "adds a payment to the booking" do
      expect {
        post admin_booking_payments_path(booking), params: {
          payment: { amount: 1500, method: "card", paid_at: Time.current, note: "Предоплата" }
        }
      }.to change(Payment, :count).by(1)

      payment = Payment.last
      expect(payment.booking).to eq(booking)
      expect(payment.method).to eq("card")
      expect(payment.note).to eq("Предоплата")
      expect(response).to redirect_to(admin_booking_path(booking))
    end

    it "rejects an invalid payment" do
      expect {
        post admin_booking_payments_path(booking), params: {
          payment: { amount: -5, method: "card", paid_at: Time.current }
        }
      }.not_to change(Payment, :count)
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "DELETE destroy" do
    it "removes the payment" do
      payment = create(:payment, booking: booking)

      expect {
        delete admin_booking_payment_path(booking, payment)
      }.to change(Payment, :count).by(-1)
      expect(response).to redirect_to(admin_booking_path(booking))
    end
  end

  describe "booking show page" do
    it "shows the payments block with balance and the payment list" do
      create(:payment, booking: booking, amount: 2000, method: "card")

      get admin_booking_path(booking)

      expect(response.body).to include("Оплаты")
      expect(response.body).to include("Оплачено:")
      expect(response.body).to include("Долг:")
      expect(response.body).to include("Карта")
      expect(response.body).to include("₽2 000")
    end

    it "shows the frozen price breakdown for nightly entries" do
      get admin_booking_path(booking)

      expect(response.body).to include("Стоимость по ночам")
      expect(response.body).to include("зафиксирована по тарифу")
    end

    it "shows the no-show fee on the booking page" do
      booking.update!(no_show_fee: 1500)

      get admin_booking_path(booking)

      expect(response.body).to include("Штраф за неявку")
      expect(response.body).to include("₽1 500")
    end
  end
end
