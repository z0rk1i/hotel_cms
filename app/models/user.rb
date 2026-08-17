class User < ApplicationRecord
  attr_reader :password, :password_confirmation

  enum :role, { guest: "guest", admin: "admin" }, validate: true

  has_many :stays, dependent: :restrict_with_error

  validates :email, uniqueness: { case_sensitive: false }, allow_blank: true
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }, if: :admin?
  validates :full_name, presence: true, if: :guest?
  validates :phone, format: { with: /\A[+\d][\d\s()-]{6,}\z/ }, allow_blank: true

  scope :admins, -> { where(role: :admin) }
  scope :guests, -> { where(role: :guest) }
  scope :vips, -> { where(is_vip: true) }
  scope :search, lambda { |query|
    like = "%#{query}%"
    where("full_name ILIKE :q OR phone ILIKE :q OR email ILIKE :q", q: like)
  }

  def admin?
    role == "admin"
  end

  def password=(plain)
    return if plain.blank?

    self.encrypted_password = BCrypt::Password.create(plain)
    @password = plain
  end

  def password_confirmation=(plain)
    @password_confirmation = plain
  end

  def valid_password?(plain)
    encrypted_password.present? && BCrypt::Password.new(encrypted_password) == plain
  end

  def guest?
    role == "guest"
  end

  def has_consent?
    consent_signed_at.present?
  end

  def confirm_consent!
    update!(consent_signed_at: Time.current) if consent_signed_at.nil?
  end

  def paid_amount
    stays.sum(&:paid_amount)
  end

  def due_amount
    stays.where(status: %w[pending confirmed checked_in]).sum(&:due_amount)
  end

  def total_spent
    stays.where(status: "checked_out").sum(&:total_price)
  end

  def stays_count
    stays.where(status: "checked_out").count
  end

  def merge_into!(target)
    Stay.where(user_id: id).update_all(user_id: target.id) # rubocop:disable Rails/SkipsModelValidations
    target.update!(
      full_name: target.full_name.presence || full_name,
      phone: target.phone.presence || phone,
      passport_number: target.passport_number.presence || passport_number,
      is_vip: is_vip || target.is_vip,
      preferences: [ target.preferences, preferences ].compact.join("\n").presence,
      consent_signed_at: target.consent_signed_at || consent_signed_at
    )
    target.reload
    destroy!
    target
  end

  def possible_duplicates
    return User.guests.none if email.blank? && phone.blank?

    User.guests.where.not(id: id).where("email = ? OR (phone <> '' AND phone = ?)", email, phone)
  end

  def letter_avatar
    full_name.to_s.strip.split(/\s+/).first&.first&.upcase
  end
end
