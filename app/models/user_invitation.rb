class UserInvitation < ApplicationRecord
  INVITABLE_ROLES = %w[owner admin accounting member viewer].freeze

  belongs_to :company
  belongs_to :invited_by, class_name: "User", optional: true

  attr_accessor :raw_token

  before_validation :normalize_email
  before_validation :set_token, on: :create
  before_validation :set_expires_at, on: :create

  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :role, presence: true, inclusion: { in: INVITABLE_ROLES }
  validates :token_digest, presence: true, uniqueness: true
  validate :email_not_already_registered, on: :create

  scope :pending, -> { where(accepted_at: nil).where("expires_at > ?", Time.current) }
  scope :recent, -> { order(created_at: :desc) }

  def self.digest(token)
    Digest::SHA256.hexdigest(token.to_s)
  end

  def self.find_by_token(token)
    find_by(token_digest: digest(token))
  end

  def accepted?
    accepted_at.present?
  end

  def expired?
    expires_at <= Time.current
  end

  def available?
    !accepted? && !expired?
  end

  private

  def normalize_email
    self.email = email.to_s.strip.downcase
  end

  def set_token
    self.raw_token ||= SecureRandom.urlsafe_base64(32)
    self.token_digest ||= self.class.digest(raw_token)
  end

  def set_expires_at
    self.expires_at ||= 7.days.from_now
  end

  def email_not_already_registered
    return if email.blank?
    return unless User.exists?(email: email)

    errors.add(:email, "は既に登録されています")
  end
end
