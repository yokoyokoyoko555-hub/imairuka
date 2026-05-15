class Product < ApplicationRecord
  include TenantScoped
  include Discard::Model
  default_scope -> { kept }  # 論理削除されていないレコードのみを取得

  # 属性の明示的な定義
  attribute :draft, :boolean, default: false

  belongs_to :company
  has_many :order_items, dependent: :restrict_with_error
  has_one_attached :image

  validates :name, presence: { message: '商品名を入力してください' }, unless: :draft?
  validates :name, length: { maximum: 100, message: '商品名は100文字以内で入力してください' }
  validates :code, presence: { message: '商品コードを入力してください' }, unless: :draft?
  validates :code, uniqueness: { scope: :discarded_at, allow_blank: true, message: 'この商品コードは既に使用されています' }, unless: :draft?
  validates :code, length: { maximum: 20, message: '商品コードは20文字以内で入力してください' }
  validates :unit_price, numericality: { greater_than_or_equal_to: 0, message: '単価は0以上の数値を入力してください' }, allow_blank: true, unless: :draft?
  validates :stock_threshold, numericality: { greater_than_or_equal_to: 0, less_than: 2147483647, message: '在庫閾値は0以上2147483647未満の数値を入力してください' }, allow_blank: true
  validates :stock_quantity, numericality: { greater_than_or_equal_to: 0, less_than: 2147483647, message: '在庫数は0以上2147483647未満の数値を入力してください' }, allow_blank: true
  validates :cost_price, numericality: { greater_than_or_equal_to: 0, less_than: 2147483647, message: '仕入価格は0以上2147483647未満の数値を入力してください' }, allow_blank: true
  validates :description, length: { maximum: 1000, message: '商品説明は1000文字以内で入力してください' }
  validates :supplier_name, length: { maximum: 100, message: '仕入先名は100文字以内で入力してください' }
  validates :supplier_contact, length: { maximum: 50, message: '担当者は50文字以内で入力してください' }
  validates :supplier_phone, format: { with: /\A\d{10,11}\z/, message: "は10桁または11桁の数字で入力してください" }, allow_blank: true
  validates :supplier_phone, length: { maximum: 15, message: '電話番号は15文字以内で入力してください' }
  validates :supplier_email, format: { with: URI::MailTo::EMAIL_REGEXP, message: "は正しい形式で入力してください" }, allow_blank: true
  validates :supplier_email, length: { maximum: 100, message: 'メールアドレスは100文字以内で入力してください' }
  validates :notes, length: { maximum: 1000, message: 'メモは1000文字以内で入力してください' }

  with_options on: :create, unless: :draft? do
    validates :image, content_type: { in: ['image/png', 'image/jpeg', 'image/gif'], message: '画像ファイル（PNG、JPEG、GIF）を選択してください' },
                      size: { less_than: 5.megabytes, message: '画像サイズは5MB以下にしてください' }
  end

  before_validation :normalize_supplier_phone

  scope :active, -> { where(is_active: true) }

  # 一時保存関連のスコープ
  scope :published, -> { where(draft: false) }
  scope :drafts, -> { where(draft: true) }

  validate :cannot_discard_with_orders, on: :discard

  # 案件に紐づいているかチェック
  def has_orders?
    order_items.exists?
  end

  # 案件に紐づいている場合の削除可否チェック
  def can_be_deleted?
    !has_orders?
  end

  def self.to_csv
    headers = %w[商品コード 商品名 単価 商品説明 ステータス]

    CSV.generate(headers: true) do |csv|
      csv << headers

      all.each do |product|
        csv << [
          product.code,
          product.name,
          product.unit_price,
          product.description,
          product.is_active ? '有効' : '無効'
        ]
      end
    end
  end

  # Cloudinary用の画像URL取得メソッド
  def image_url(size = :medium)
    return nil unless image.attached?

    begin
      case size
      when :thumbnail
        image.variant(resize_to_limit: [150, 150]).processed.url
      when :medium
        image.variant(resize_to_limit: [300, 300]).processed.url
      when :large
        image.variant(resize_to_limit: [600, 600]).processed.url
      else
        image.url
      end
    rescue ActiveStorage::IntegrityError => e
      Rails.logger.error "ActiveStorage::IntegrityError for Product ##{id} image: #{e.message}"
      image.url
    end
  end

  private

  def normalize_supplier_phone
    if supplier_phone.present?
      # 数字とハイフン以外が含まれているかチェック
      if supplier_phone.match?(/[^\d-]/)
        errors.add(:supplier_phone, "には数字とハイフンのみ入力してください")
        return
      end
      # ハイフンを削除して数字のみにする
      self.supplier_phone = supplier_phone.gsub(/[^\d]/, '')
    end
  end

  def cannot_discard_with_orders
    if order_items.exists?
      errors.add(:base, '案件に紐づいているため削除できません。先に案件を削除してください。')
      throw(:abort)
    end
  end
end
