class User < ApplicationRecord
  devise :database_authenticatable, :registerable, :recoverable, :rememberable, :validatable,
         :omniauthable, omniauth_providers: %i[vkontakte yandex]

  has_many :bookings, dependent: :nullify
  has_many :guests, through: :bookings
  has_many :service_orders, dependent: :destroy
  has_many :notifications, dependent: :destroy

  validates :full_name, presence: true
  validates :phone, length: { maximum: 30 }, allow_blank: true

  def self.from_omniauth(auth)
    find_or_initialize_by(provider: auth.provider, uid: auth.uid).tap do |user|
      user.email = auth.info.email.presence || "#{auth.provider}-#{auth.uid}@example.com"
      user.full_name = auth.info.name if user.full_name.blank?
      user.password = Devise.friendly_token[0, 20] if user.encrypted_password.blank?
      user.save
    end
  end

  def email_deliverable?
    email.present? && !email.end_with?("@example.com")
  end
end
