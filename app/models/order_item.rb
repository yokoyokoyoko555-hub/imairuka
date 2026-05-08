class OrderItem < ApplicationRecord
  belongs_to :order
  belongs_to :product

  before_validation :calculate_amounts

  private

  def calculate_amounts
    return unless product && quantity.present?

    # 商品の単価を設定
    self.unit_price = product.unit_price || 0
    # 金額を計算（単価 × 数量）
    self.amount = (unit_price || 0) * quantity
  end
end 