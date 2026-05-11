class Company < ApplicationRecord
  attr_accessor :ai_api_key, :clear_ai_api_key

  has_many :users, dependent: :restrict_with_error
  has_many :user_invitations, dependent: :destroy
  has_many :customers, dependent: :restrict_with_error
  has_many :products, dependent: :restrict_with_error
  has_many :order_statuses, dependent: :restrict_with_error
  has_many :orders, dependent: :restrict_with_error
  has_many :quotations, dependent: :restrict_with_error
  has_many :invoices, dependent: :restrict_with_error
  has_many :receipts, dependent: :restrict_with_error
  has_many :delivery_notes, dependent: :restrict_with_error
  has_many :payment_records, dependent: :restrict_with_error

  enum :contract_status, {
    trialing: "trialing",
    active: "active",
    past_due: "past_due",
    suspended: "suspended",
    canceled: "canceled"
  }, default: "trialing"

  validates :name, presence: true, length: { maximum: 100 }
  validates :invoice_number, presence: true, format: { with: /\AT\d{13}\z/ }, length: { maximum: 20 }
  validates :postal_code, presence: true, format: { with: /\A\d{7}\z/ }, length: { maximum: 10 }
  validates :address, presence: true, length: { maximum: 500 }
  validates :phone, presence: true, format: { with: /\A\d{10,11}\z/ }, length: { maximum: 15 }
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }, length: { maximum: 100 }
  validates :representative, presence: true, length: { maximum: 50 }
  validates :business_type, presence: true, length: { maximum: 50 }
  validates :tenant_slug, presence: true, uniqueness: true

  before_validation :set_tenant_slug, :normalize_postal_code, :normalize_phone
  before_save :apply_ai_api_key_change

  USER_LIMITS = {
    "starter" => 1,
    "standard" => 3,
    "pro" => 10,
    "enterprise" => nil
  }.freeze

  def contract_active?
    trialing? || active?
  end

  def account_invitation_unlocked?
    active?
  end

  def user_limit
    USER_LIMITS.fetch(plan_name.to_s, USER_LIMITS["standard"])
  end

  def user_limit_label
    user_limit || "無制限"
  end

  def active_users_count
    users.where(active: true).count
  end

  def pending_invitations_count
    user_invitations.pending.count
  end

  def user_slots_used
    active_users_count + pending_invitations_count
  end

  def remaining_user_slots
    return nil if user_limit.nil?

    [user_limit - user_slots_used, 0].max
  end

  def can_invite_user?
    return false unless account_invitation_unlocked?
    return true if user_limit.nil?

    user_slots_used < user_limit
  end

  def user_limit_message
    return "アカウント追加は月額契約が有効になると利用できます。" unless account_invitation_unlocked?
    return "このプランではユーザーを無制限に招待できます。" if user_limit.nil?
    return "招待可能です。残り#{remaining_user_slots}名まで追加できます。" if can_invite_user?

    "現在のプラン上限に達しています。プラン変更または追加課金が必要です。"
  end

  def stripe_connected?
    stripe_account_id.present? && stripe_charges_enabled?
  end

  def ai_configured?
    ai_api_key_ciphertext.present?
  end

  def decrypted_ai_api_key
    return nil if ai_api_key_ciphertext.blank?

    ai_encryptor.decrypt_and_verify(ai_api_key_ciphertext)
  rescue ActiveSupport::MessageEncryptor::InvalidMessage
    nil
  end

  def masked_ai_api_key
    ai_configured? ? "設定済み" : "未設定"
  end

  def stripe_connect_status
    return "未連携" if stripe_account_id.blank?
    return "利用可能" if stripe_charges_enabled?
    return "審査中" if stripe_details_submitted?

    "設定未完了"
  end

  private

  def set_tenant_slug
    return if tenant_slug.present?

    self.tenant_slug = name.to_s.parameterize.presence || "company-#{SecureRandom.hex(4)}"
  end

  def normalize_postal_code
    return if postal_code.blank?

    if postal_code.match?(/[^\d-]/)
      errors.add(:postal_code, "は数字とハイフンのみで入力してください")
      return
    end

    self.postal_code = postal_code.gsub(/[^\d]/, "")
  end

  def normalize_phone
    return if phone.blank?

    if phone.match?(/[^\d-]/)
      errors.add(:phone, "は数字とハイフンのみで入力してください")
      return
    end

    self.phone = phone.gsub(/[^\d]/, "")
  end

  def apply_ai_api_key_change
    if ActiveModel::Type::Boolean.new.cast(clear_ai_api_key)
      self.ai_api_key_ciphertext = nil
      return
    end

    return if ai_api_key.blank?

    self.ai_api_key_ciphertext = ai_encryptor.encrypt_and_sign(ai_api_key.strip)
  end

  def ai_encryptor
    key = ActiveSupport::KeyGenerator.new(Rails.application.secret_key_base).generate_key("company-ai-api-key", 32)
    ActiveSupport::MessageEncryptor.new(key)
  end
end
