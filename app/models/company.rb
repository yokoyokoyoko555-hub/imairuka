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

  DEFAULT_PLAN_NAME = "standard".freeze
  PLAN_LABEL = "基本プラン".freeze
  INCLUDED_USER_LIMIT = 1
  ADDITIONAL_USER_MONTHLY_AMOUNT = ENV.fetch("ADDITIONAL_USER_MONTHLY_AMOUNT", "3000").to_i
  AI_PROVIDERS = {
    "openai" => "OpenAI",
    "claude" => "Claude",
    "gemini" => "Gemini"
  }.freeze
  DEFAULT_AI_MODELS = {
    "openai" => "gpt-5",
    "claude" => "claude-sonnet-4-5",
    "gemini" => "gemini-2.5-pro"
  }.freeze

  enum :contract_status, {
    pending_review: "pending_review",
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
  validates :ai_provider, presence: true, inclusion: { in: AI_PROVIDERS.keys }
  validates :ai_model, presence: true, length: { maximum: 100 }

  before_validation :set_tenant_slug, :normalize_postal_code, :normalize_phone
  before_save :apply_ai_api_key_change

  USER_LIMITS = {
    DEFAULT_PLAN_NAME => INCLUDED_USER_LIMIT
  }.freeze

  def contract_active?
    trialing? || active?
  end

  def service_available?
    contract_active?
  end

  def contract_status_label
    {
      "pending_review" => "申込受付",
      "trialing" => "トライアル",
      "active" => "利用中",
      "past_due" => "支払確認中",
      "suspended" => "停止中",
      "canceled" => "解約"
    }.fetch(contract_status, contract_status)
  end

  def contract_status_badge_class
    {
      "pending_review" => "bg-warning text-dark",
      "trialing" => "bg-info text-dark",
      "active" => "bg-success",
      "past_due" => "bg-warning text-dark",
      "suspended" => "bg-secondary",
      "canceled" => "bg-dark"
    }.fetch(contract_status, "bg-secondary")
  end

  def account_invitation_unlocked?
    service_available?
  end

  def included_user_limit
    INCLUDED_USER_LIMIT
  end

  def user_limit
    USER_LIMITS.fetch(DEFAULT_PLAN_NAME) + additional_user_slots.to_i
  end

  def plan_label
    PLAN_LABEL
  end

  def user_limit_label
    "#{user_limit}名"
  end

  def additional_user_monthly_amount
    ADDITIONAL_USER_MONTHLY_AMOUNT
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
    return "基本プランは全機能利用可能で、標準#{included_user_limit}名まで利用できます。追加枠#{additional_user_slots.to_i}名、残り#{remaining_user_slots}名まで招待できます。" if can_invite_user?

    "基本プランは標準#{included_user_limit}名までです。追加アカウントは1名ごとに月額課金が必要です。"
  end

  def stripe_connected?
    stripe_account_id.present? && stripe_charges_enabled?
  end

  def ai_provider_label
    AI_PROVIDERS.fetch(ai_provider, ai_provider)
  end

  def ai_model_or_default
    ai_model.presence || DEFAULT_AI_MODELS.fetch(ai_provider, DEFAULT_AI_MODELS["openai"])
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
    self.tenant_slug = tenant_slug.to_s.parameterize if tenant_slug.present?
    return if tenant_slug.present? && !self.class.where.not(id: id).exists?(tenant_slug: tenant_slug)

    base_slug = name.to_s.parameterize.presence || "company"
    candidate = base_slug

    while self.class.where.not(id: id).exists?(tenant_slug: candidate)
      candidate = "#{base_slug}-#{SecureRandom.hex(3)}"
    end

    self.tenant_slug = candidate
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
