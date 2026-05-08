class DeliveryNoteHistory < ApplicationRecord
  include Discard::Model
  default_scope -> { kept }

  belongs_to :delivery_note

  validates :action, presence: true

  scope :recent, -> { order(created_at: :desc) }

  def description
    case action
    when '納品書作成'
      '納品書を作成しました'
    when '納品書更新'
      '納品書情報を更新しました'
    else
      "#{action}しました"
    end
  end
end
