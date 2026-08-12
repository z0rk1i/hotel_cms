class PricePeriod < ApplicationRecord
  validates :name, presence: true
  validates :starts_on, :ends_on, presence: true
  validates :multiplier, numericality: { greater_than: 0 }
  validate :ends_after_starts
  validate :no_overlap

  scope :covering, ->(date) { where("starts_on <= ? AND ends_on >= ?", date, date) }

  def self.multiplier_on(date)
    covering(date).order(:starts_on, :id).first&.multiplier || 1
  end

  private

  def ends_after_starts
    return if starts_on.blank? || ends_on.blank?

    errors.add(:ends_on, "должна быть позже даты начала") if ends_on < starts_on
  end

  def no_overlap
    return if starts_on.blank? || ends_on.blank?

    overlapping = self.class.where.not(id: id)
                            .where("starts_on <= ? AND ends_on >= ?", ends_on, starts_on)
    errors.add(:starts_on, "пересекается с другим периодом") if overlapping.exists?
  end
end
