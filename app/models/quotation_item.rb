class QuotationItem < ApplicationRecord
  include Discard::Model
  default_scope -> { kept }  # 論理削除されていないレコードのみを取得

  belongs_to :quotation

  validates :product_code, presence: { message: '商品コードを入力してください' }, length: { maximum: 20, message: '商品コードは20文字以内で入力してください' }
  validates :product_name, presence: { message: '商品名を入力してください' }, length: { maximum: 100, message: '商品名は100文字以内で入力してください' }
  validates :unit_price, numericality: { greater_than_or_equal_to: 0, message: '単価は0以上の数値を入力してください' }, presence: { message: '単価を入力してください' }
  validates :quantity, numericality: { greater_than: 0, message: '数量は1以上の数値を入力してください' }, presence: { message: '数量を入力してください' }

  before_save :calculate_amount

  # 金額を計算するメソッド
  def amount
    if unit_price.present? && quantity.present?
      unit_price * quantity
    else
      read_attribute(:amount) || 0
    end
  end

  def tax_rate_label
    case tax_rate
    when 1
      '10%'
    when 2
      '8% (軽減税率)'
    when 3
      '8%'
    when 4
      '0%'
    else
      ''
    end
  end

  private

  def calculate_amount
    self.amount = unit_price * quantity if unit_price.present? && quantity.present?
  end
end
