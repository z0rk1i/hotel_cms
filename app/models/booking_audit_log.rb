class BookingAuditLog < ApplicationRecord
  belongs_to :booking
  belongs_to :administrator, optional: true

  scope :ordered, -> { order(created_at: :desc, id: :desc) }
end
