class Company < ApplicationRecord
  has_many :users, dependent: :restrict_with_error
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

  def contract_active?
    trialing? || active?
  end

  def stripe_connected?
    stripe_account_id.present? && stripe_charges_enabled?
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
end
