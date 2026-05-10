class PaymentRecord < ApplicationRecord
  include TenantScoped
  belongs_to :order
  belongs_to :company, optional: true

  enum :status, {
    pending: "pending",
    paid: "paid",
    failed: "failed",
    canceled: "canceled"
  }

  validates :amount, numericality: { greater_than_or_equal_to: 0 }
  validates :currency, presence: true
  validates :stripe_checkout_session_id, uniqueness: true, allow_blank: true

  def self.status_text(status)
    case status.to_s
    when "paid"
      "入金済み"
    when "failed"
      "失敗"
    when "canceled"
      "キャンセル"
    else
      "未入金"
    end
  end
end
