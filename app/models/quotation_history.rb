class QuotationHistory < ApplicationRecord
  include Discard::Model
  default_scope -> { kept }  # 論理削除されていないレコードのみを取得

  belongs_to :quotation

  validates :action, presence: { message: 'アクションを入力してください' }

  scope :recent, -> { order(created_at: :desc) }

  def description
    case action
    when '見積書作成'
      '見積書を作成しました'
    when '見積書更新'
      '見積書情報を更新しました'
    else
      "#{action}しました"
    end
  end
end
