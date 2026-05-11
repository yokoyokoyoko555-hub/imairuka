class User < ApplicationRecord
  has_secure_password

  belongs_to :company

  enum :role, {
    platform_admin: "platform_admin",
    owner: "owner",
    admin: "admin",
    accounting: "accounting",
    member: "member",
    viewer: "viewer"
  }, default: "owner"

  validates :email, presence: true, uniqueness: true
  validates :password, presence: true, length: { minimum: 6 }, if: :password_digest_changed?
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
end
