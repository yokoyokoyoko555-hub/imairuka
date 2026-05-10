class Invoice < ApplicationRecord
  include TenantScoped
  include Discard::Model
  default_scope -> { kept }

  # 属性の明示的な定義
  attribute :draft, :boolean, default: false
  attribute :payment_method, :string
  attribute :payment_due_date, :date

  belongs_to :company
  has_many :invoice_items, -> { kept }, dependent: :destroy
  has_many :invoice_histories, dependent: :destroy
  belongs_to :quotation, optional: true

  # ステータスのenum定義
  enum :status, {
    pending: 'pending',
    sent: 'sent',
    waiting_payment: 'waiting_payment',
    paid: 'paid'
  }

  validates :invoice_number, uniqueness: { allow_blank: true }, unless: :draft?
  validates :invoice_date, presence: true, unless: :draft?
  validates :payment_method, length: { maximum: 100, message: '支払方法は100文字以内で入力してください' }, allow_blank: true
  validates :status, inclusion: { in: %w[pending sent waiting_payment paid] }, allow_blank: true
  validates :customer_name, presence: true, length: { maximum: 100, message: '顧客名は100文字以内で入力してください' }, unless: :draft?
  validates :staff_name, presence: true, length: { maximum: 50, message: '担当者名は50文字以内で入力してください' }, unless: :draft?
  validates :subject, presence: true, length: { maximum: 200, message: '件名は200文字以内で入力してください' }, unless: :draft?
  validates :customer_address, length: { maximum: 200, message: '顧客住所は200文字以内で入力してください' }, allow_blank: true

  validates :notes, length: { maximum: 1000, message: '備考は1000文字以内で入力してください' }, allow_blank: true
  validate :must_have_at_least_one_item, unless: :draft?

  accepts_nested_attributes_for :invoice_items, allow_destroy: true, reject_if: :all_blank

  # 一時保存関連のスコープ
  scope :published, -> { where(draft: false) }
  scope :drafts, -> { where(draft: true) }

  before_create :set_invoice_number
  before_save :calculate_total_amount

  after_create :record_creation_history
  after_update :record_update_history

  # Ransackで検索可能な属性を定義
  def self.ransackable_attributes(auth_object = nil)
    ["created_at", "customer_name", "discarded_at", "id", "invoice_date", "invoice_number", "staff_name", "status", "total_amount", "payment_due_date", "payment_method", "notes", "updated_at"]
  end

  # Ransackで検索可能なアソシエーションを定義
  def self.ransackable_associations(auth_object = nil)
    ["invoice_items", "invoice_histories"]
  end

  # ステータスの日本語表示
  def status_text
    case status
    when 'pending'
      '送付待ち'
    when 'sent'
      '送付済み'
    when 'waiting_payment'
      '入金待ち'
    when 'paid'
      '入金済み'
    else
      '不明'
    end
  end

  # ステータスの色
  def status_color
    case status
    when 'pending'
      'secondary'
    when 'sent'
      'info'
    when 'waiting_payment'
      'warning'
    when 'paid'
      'success'
    else
      'secondary'
    end
  end

  # 税込金額（明細ごとの税率を考慮した合計）を返す
  def total_amount_with_tax
    subtotal = 0
    tax_total = 0
    invoice_items.each do |item|
      amount = (item.unit_price || 0) * (item.quantity || 0)
      subtotal += amount
      case item.tax_rate.to_i
      when 1
        tax_total += (amount * 0.1).round
      when 2, 3
        tax_total += (amount * 0.08).round
      end
    end
    subtotal + tax_total
  end

  private

  def set_invoice_number
    return if invoice_number.present?
    
    # 最新の請求書番号を取得（論理削除されていないもの）
    last_invoice = Invoice.kept.order(invoice_number: :desc).first
    
    if last_invoice && last_invoice.invoice_number.match?(/^I\d{6}$/)
      # 既存の番号から連番を抽出して+1
      last_number = last_invoice.invoice_number[1..-1].to_i
      next_number = last_number + 1
    else
      # 初回の場合
      next_number = 1
    end
    
    # 重複しない番号を見つけるまでループ
    loop do
      candidate_number = "I#{format('%06d', next_number)}"
      unless Invoice.kept.exists?(invoice_number: candidate_number)
        self.invoice_number = candidate_number
        break
      end
      next_number += 1
    end
  end

  def calculate_total_amount
    self.total_amount = invoice_items.reject(&:marked_for_destruction?).sum { |item| item.amount.to_i }
  end

  def record_creation_history
    action_text = draft? ? '一時保存' : '請求書作成'
    invoice_histories.create!(
      action: action_text
    )
  end

  def record_update_history
    action_text = draft? ? '一時保存' : '請求書更新'
    invoice_histories.create!(
      action: action_text
    )
  end

  def must_have_at_least_one_item
    if invoice_items.reject(&:marked_for_destruction?).empty?
      errors.add(:base, '商品を1つ以上追加してください')
    end
  end

  def no_items?
    invoice_items.reject(&:marked_for_destruction?).empty?
  end
end
