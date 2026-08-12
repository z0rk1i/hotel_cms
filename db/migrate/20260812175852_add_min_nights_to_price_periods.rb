class AddMinNightsToPricePeriods < ActiveRecord::Migration[8.1]
  def change
    add_column :price_periods, :min_nights, :integer
  end
end
