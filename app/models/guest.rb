class Guest < ApplicationRecord
  has_many :bookings, dependent: :restrict_with_error

  validates :full_name, presence: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true
  validates :email, uniqueness: true, allow_blank: true
  validates :passport_number, uniqueness: true, allow_blank: true

  scope :search, ->(query) do
    return all if query.blank?

    pattern = "%#{sanitize_sql_like(query)}%"
    where(arel_table[:full_name].matches(pattern).or(arel_table[:phone].matches(pattern)))
  end
end
