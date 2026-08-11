class Administrator < ApplicationRecord
  devise :database_authenticatable, :recoverable, :rememberable, :validatable

  validates :email, presence: true
end
