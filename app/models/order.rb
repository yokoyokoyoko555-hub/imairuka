class Order < ApplicationRecord
  include TenantScoped
  include Discard::Model
  default_scope -> { kept }  # 論理削除されていないレコードのみを取得

  # 属性の明示的な定義
  attribute :draft, :boolean, default: false
  attribute :payment_method, :string

  belongs_to :company
  belongs_to :customer
  belongs_to :order_status
  has_many :order_items, dependent: :destroy
  has_many :products, through: :order_items
  has_many :histories, class_name: 'OrderHistory', dependent: :destroy
  has_many :payment_records, dependent: :destroy
  has_many :project_tasks, class_name: "OrderProjectTask", dependent: :destroy
  has_many :project_issues, class_name: "OrderProjectIssue", dependent: :destroy
  has_many :assignments, class_name: "OrderAssignment", dependent: :destroy
  has_many :assigned_users, through: :assignments, source: :user

  validates :order_number, uniqueness: { message: 'この案件番号は既に使用されています' }, unless: :draft?
  validates :project_name, length: { maximum: 120 }
  validates :project_summary, length: { maximum: 4000 }
  validates :order_date, presence: { message: '注文日を入力してください' }
  validates :staff_name, presence: { message: '担当者名を入力してください' }, length: { maximum: 50, message: '担当者名は50文字以内で入力してください' }, unless: :draft?
  validates :order_status, presence: { message: 'ステータスを選択してください' }, unless: :draft?
  validates :total_amount, presence: { message: '合計金額を入力してください' }, 
            numericality: { greater_than_or_equal_to: 0, message: '合計金額は0以上の数値を入力してください' }
  validates :customer_id, presence: { message: '顧客を選択してください' }, unless: :draft?
  validates :notes, length: { maximum: 200, message: '備考は200文字以内で入力してください' }, allow_blank: true
  validates :delivery_address, length: { maximum: 200, message: '納品先は200文字以内で入力してください' }, allow_blank: true

  validate :validate_order_items, on: [:create, :update], unless: :draft?

  accepts_nested_attributes_for :order_items, allow_destroy: true, reject_if: :all_blank

  enum :payment_method, {
    credit_card: '0',
    bank_transfer: '1',
    cash: '2'
  }

  # 一時保存関連のスコープ
  scope :published, -> { where(draft: false) }
  scope :drafts, -> { where(draft: true) }

  def self.payment_method_text(method)
    case method.to_s
    when 'credit_card', '0'
      'クレジットカード'
    when 'bank_transfer', '1'
      '銀行振込'
    when 'cash', '2'
      '現金'
    else
      '未選択'
    end
  end

  before_validation :set_order_number, on: :create
  before_save :calculate_total_amount

  after_create :record_creation_history
  after_update :record_update_history

  private

  def validate_order_items
    return if order_items.reject(&:marked_for_destruction?).any?

    errors.add(:order_items, '商品を選択してください')
  end

  def validate_order_item_quantities
    order_items.reject(&:marked_for_destruction?).each do |item|
      if item.quantity.blank? || item.quantity <= 0
        errors.add(:order_items, '数量は1以上を入力してください')
      end
    end
  end

  def set_order_number
    return if order_number.present?
    
    # 既存の最大番号を取得（一時保存データも含む）
    last_order = Order.kept.where.not(order_number: nil).order(order_number: :desc).first
    
    if last_order && last_order.order_number.present? && last_order.order_number.match?(/^O\d{6}$/)
      last_number = last_order.order_number[1..-1].to_i
      next_number = last_number + 1
    else
      next_number = 1
    end
    
    # 重複しない番号を見つけるまでループ
    loop do
      candidate_number = "O#{format('%06d', next_number)}"
      unless Order.kept.exists?(order_number: candidate_number)
        self.order_number = candidate_number
        break
      end
      next_number += 1
    end
  end

  def calculate_total_amount
    self.total_amount = order_items.reject(&:marked_for_destruction?).sum { |item| item.amount.to_i }
  end

  def record_creation_history
    return if draft?
    histories.create!(
      action: :created,
      description: "案件を登録しました",
      staff_name: staff_name
    )
  end

  def record_update_history
    return if draft?
    histories.create!(
      action: :updated,
      description: "案件情報を更新しました",
      staff_name: staff_name
    )
  end
end
