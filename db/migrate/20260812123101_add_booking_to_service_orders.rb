class AddBookingToServiceOrders < ActiveRecord::Migration[8.1]
  def change
    add_reference :service_orders, :booking, null: false, foreign_key: true
  end
end
