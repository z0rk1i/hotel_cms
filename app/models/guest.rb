class Guest < ApplicationRecord
  has_many :bookings, dependent: :restrict_with_error
  has_many :payments, through: :bookings

  validates :full_name, presence: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true
  validates :email, uniqueness: true, allow_blank: true
  validates :passport_number, uniqueness: true, allow_blank: true

  scope :search, ->(query) do
    return all if query.blank?

    pattern = "%#{sanitize_sql_like(query)}%"
    where(arel_table[:full_name].matches(pattern).or(arel_table[:phone].matches(pattern)))
  end

  def total_spent
    bookings.joins(:payments).sum("payments.amount")
  end

  def completed_stays
    bookings.checked_out.count
  end

  def possible_duplicates
    identities = {
      email: email,
      phone: phone,
      passport_number: passport_number
    }.reject { |_, value| value.blank? }

    return Guest.none if identities.empty?

    conditions = identities.map do |column, _|
      column == :email ? "LOWER(email) = LOWER(?)" : "#{column} = ?"
    end
    values = identities.values
    Guest.where.not(id: id).where(conditions.join(" OR "), *values).order(:created_at)
  end

  def merge_into!(target)
    return false if target.nil? || target.id == id

    Guest.transaction do
      bookings.update_all(guest_id: target.id)
      target.update!(
        is_vip: target.is_vip || is_vip,
        preferences: target.preferences.presence || preferences,
        phone: target.phone.presence || phone,
        passport_number: passport_number.presence,
        notes: [ target.notes, notes ].compact_blank.join("\n").presence
      )
      destroy!
    end
    true
  rescue ActiveRecord::RecordInvalid => e
    errors.add(:base, "Не удалось объединить: #{e.message}")
    false
  end
end
