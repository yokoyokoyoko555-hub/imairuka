class InvoiceHistory < ApplicationRecord
  belongs_to :invoice

  validates :action, presence: true

  # 履歴の説明を返す
  def description
    "#{action} (#{created_at.strftime('%Y/%m/%d %H:%M')})"
  end
end
