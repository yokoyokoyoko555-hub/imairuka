class Vendor < ApplicationRecord
  has_many :companies, dependent: :restrict_with_error

  STATUSES = {
    "active" => "有効",
    "suspended" => "停止中",
    "ended" => "終了"
  }.freeze

  before_validation :normalize_code

  validates :code, presence: true, uniqueness: true, length: { maximum: 40 }
  validates :name, presence: true, length: { maximum: 100 }
  validates :email, allow_blank: true, format: { with: URI::MailTo::EMAIL_REGEXP }, length: { maximum: 100 }
  validates :status, presence: true, inclusion: { in: STATUSES.keys }

  scope :active, -> { where(status: "active") }
  scope :recent, -> { order(created_at: :desc) }

  def status_label
    STATUSES.fetch(status, status)
  end

  def status_badge_class
    {
      "active" => "bg-success",
      "suspended" => "bg-secondary",
      "ended" => "bg-dark"
    }.fetch(status, "bg-secondary")
  end

  def display_name
    "#{name}（#{code}）"
  end

  private

  def normalize_code
    self.code = code.to_s.strip.upcase if code.present?
  end
end
