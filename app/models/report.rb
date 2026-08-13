class Report < ApplicationRecord
  validate(
    :periods_are_valid
  )

  scope :monthly, lambda { |month|
    where(kind: "month", period_start: month.beginning_of_month, period_end: month.end_of_month)
  }

  def self.refresh!(from:, to:)
    report = find_or_initialize_by(period_start: from, period_end: to, kind: range_kind(from, to))
    report.data = Reports::Builder.build(from: from, to: to)
    report.save!
    report
  end

  def self.range_kind(from, to)
    from == from.beginning_of_month && to == to.end_of_month ? "month" : "custom"
  end

  def plan_revenue = data["plan_revenue"].to_f
  def fact_revenue = data["fact_revenue"].to_f
  def monthly_booked_revenue = data["monthly_booked_revenue"].to_f
  def occupancy_rate = data["occupancy_rate"].to_f
  def booked_nights = data["booked_nights"].to_i
  def capacity_nights = data["capacity_nights"].to_i
  def by_category = data["by_category"] || {}
  def nightly = data["nights"] || {}

  private

  def periods_are_valid
    return if period_start.nil? || period_end.nil?

    errors.add(:period_end, "должна быть не раньше начала периода") unless period_end >= period_start
  end
end