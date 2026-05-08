class User < ApplicationRecord
  has_secure_password

  validates :email, presence: true, uniqueness: true
  validates :password, presence: true, length: { minimum: 6 }, if: :password_digest_changed?

  # --- remember me 機能 ---
  attr_accessor :remember_token

  def self.new_token
    SecureRandom.urlsafe_base64
  end

  def remember
    self.remember_token = User.new_token
    update!(remember_digest: BCrypt::Password.create(remember_token))
  end

  def authenticated?(token)
    return false if remember_digest.nil?
    BCrypt::Password.new(remember_digest).is_password?(token)
  end

  def forget
    update!(remember_digest: nil)
  end
end 