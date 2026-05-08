class Customer < ApplicationRecord
  include Discard::Model
  default_scope -> { kept }  # 論理削除されていないレコードのみを取得

  # 属性の明示的な定義
  attribute :draft, :boolean, default: false

  has_many :orders

  validates :name, presence: { message: '顧客名を入力してください' }, unless: :draft?
  validates :name, length: { maximum: 50, message: '顧客名は50文字以内で入力してください' }
  validates :code, presence: { message: '顧客コードを入力してください' }, unless: :draft?
  validates :code, uniqueness: { scope: :discarded_at, allow_blank: true, message: 'この顧客コードは既に使用されています' }, unless: :draft?
  validates :code, length: { maximum: 20, message: '顧客コードは20文字以内で入力してください' }
  validates :company_name, presence: { message: '会社名を入力してください' }, unless: :draft?
  validates :company_name, length: { maximum: 100, message: '会社名は100文字以内で入力してください' }
  validates :industry, presence: { message: '業種を選択してください' }, unless: :draft?
  validates :status, presence: { message: 'ステータスを選択してください' }, 
                     inclusion: { in: %w[active prospect inactive], message: 'ステータスを選択してください' }, unless: :draft?
  validates :representative_name, length: { maximum: 50, message: '代表者名は50文字以内で入力してください' }
  validates :business_description, length: { maximum: 500, message: '事業内容は500文字以内で入力してください' }
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP, message: "は正しい形式で入力してください" }, allow_blank: true
  validates :email, length: { maximum: 100, message: 'メールアドレスは100文字以内で入力してください' }
  validates :phone, format: { with: /\A\d{10,11}\z/, message: "は10桁または11桁の数字で入力してください" }, allow_blank: true
  validates :phone, length: { maximum: 15, message: '電話番号は15文字以内で入力してください' }
  validates :address, length: { maximum: 500, message: '住所は500文字以内で入力してください' }
  validates :payment_term, length: { maximum: 100, message: '支払条件は100文字以内で入力してください' }
  validates :invoice_email, format: { with: URI::MailTo::EMAIL_REGEXP, message: "は正しい形式で入力してください" }, allow_blank: true
  validates :invoice_email, length: { maximum: 100, message: '請求書メールは100文字以内で入力してください' }
  validates :notes, length: { maximum: 1000, message: 'メモは1000文字以内で入力してください' }
  validates :capital, numericality: { greater_than_or_equal_to: 0, less_than: 2147483647, message: '資本金は0以上2147483647未満の数値を入力してください' }, allow_blank: true
  validates :employee_count, numericality: { greater_than_or_equal_to: 0, less_than: 2147483647, message: '従業員数は0以上2147483647未満の数値を入力してください' }, allow_blank: true

  validate :cannot_discard_with_orders, on: :discard

  before_validation :normalize_phone

  scope :active, -> { where(is_active: true) }
  scope :prospects, -> { where(status: 'prospect') }
  scope :active_customers, -> { where(status: 'active') }
  scope :inactive_customers, -> { where(status: 'inactive') }

  # 一時保存関連のスコープ
  scope :published, -> { where(draft: false) }
  scope :drafts, -> { where(draft: true) }

  # ステータスの日本語表示
  def status_text
    case status
    when 'active'
      '取引中'
    when 'prospect'
      '見込み'
    when 'inactive'
      '取引終了'
    else
      '不明'
    end
  end

  # 最終取引日の取得
  def last_transaction_date
    orders.order(order_date: :desc).first&.order_date
  end

  # 取引回数の取得
  def transaction_count
    orders.count
  end

  # 総取引金額の取得
  def total_transaction_amount
    orders.sum(:total_amount)
  end

  def self.to_csv
    headers = %w[顧客コード 顧客名 会社名 業種 ステータス]
    CSV.generate(headers: true) do |csv|
      csv << headers
      all.each do |customer|
        csv << [
          customer.code,
          customer.name,
          customer.company_name,
          customer.industry,
          customer.status
        ]
      end
    end
  end

  private

  def normalize_phone
    if phone.present?
      # 数字とハイフン以外が含まれているかチェック
      if phone.match?(/[^\d-]/)
        errors.add(:phone, "には数字とハイフンのみ入力してください")
        return
      end
      # ハイフンを削除して数字のみにする
      self.phone = phone.gsub(/[^\d]/, '')
    end
  end

  def cannot_discard_with_orders
    if orders.kept.exists?
      errors.add(:base, '案件が紐づいているため削除できません。先に案件を削除してください。')
      throw(:abort)
    end
  end
end 