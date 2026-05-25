class User < ApplicationRecord
  has_secure_password

  belongs_to :company

  PASSWORD_FORMAT = /\A(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^A-Za-z0-9]).+\z/
  LOGIN_OTP_TTL = 10.minutes
  LOGIN_OTP_MAX_ATTEMPTS = 5

  enum :role, {
    platform_admin: "platform_admin",
    owner: "owner",
    admin: "admin",
    accounting: "accounting",
    member: "member",
    viewer: "viewer"
  }, default: "owner"

  before_validation :normalize_email

  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password,
    length: { in: 8..16 },
    format: {
      with: PASSWORD_FORMAT,
      message: "は小文字・大文字・数字・記号をすべて含めてください"
    },
    if: :password_required?
  validates :role, presence: true

  scope :active, -> { where(active: true) }

  ROLE_LABELS = {
    "platform_admin" => "運営管理者",
    "owner" => "オーナー",
    "admin" => "管理者",
    "accounting" => "経理",
    "member" => "一般",
    "viewer" => "閲覧のみ"
  }.freeze

  attr_accessor :remember_token

  def self.new_token
    SecureRandom.urlsafe_base64
  end

  def display_name
    name.presence || email
  end

  def role_label
    ROLE_LABELS.fetch(role, role)
  end

  def can_manage_contract?
    platform_admin? || owner?
  end

  def can_manage_users?
    platform_admin? || owner? || admin?
  end

  def can_manage_payments?
    platform_admin? || owner? || admin? || accounting?
  end

  def read_only?
    viewer?
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

  def generate_login_otp!
    code = format("%06d", SecureRandom.random_number(1_000_000))
    update!(
      login_otp_digest: BCrypt::Password.create(code),
      login_otp_sent_at: Time.current,
      login_otp_expires_at: LOGIN_OTP_TTL.from_now,
      login_otp_attempts: 0
    )
    code
  end

  def verify_login_otp(code)
    return false if login_otp_digest.blank?
    return false if login_otp_expires_at.blank? || login_otp_expires_at.past?
    return false if login_otp_attempts.to_i >= LOGIN_OTP_MAX_ATTEMPTS

    if BCrypt::Password.new(login_otp_digest).is_password?(code.to_s.strip)
      clear_login_otp!
      true
    else
      increment!(:login_otp_attempts)
      false
    end
  end

  def clear_login_otp!
    update!(
      login_otp_digest: nil,
      login_otp_sent_at: nil,
      login_otp_expires_at: nil,
      login_otp_attempts: 0
    )
  end

  private

  def normalize_email
    self.email = email.to_s.strip.downcase
  end

  def password_required?
    password.present? || password_digest.blank?
  end
end
