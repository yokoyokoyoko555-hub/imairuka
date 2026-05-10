class OrderStatus < ApplicationRecord
  include TenantScoped
  belongs_to :company
  has_many :orders, dependent: :restrict_with_error

  validates :name, presence: true, uniqueness: true, length: { maximum: 50, message: 'ステータス名は50文字以内で入力してください' }
  validates :code, presence: true, uniqueness: true, format: { with: /\A[a-z0-9_]+\z/, message: 'は半角英数字とアンダースコアのみ使用できます' }, length: { maximum: 20, message: 'ステータスコードは20文字以内で入力してください' }
  validates :display_order, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 1 }
  validates :color, format: { with: /\A#[0-9a-f]{6}\z/i, message: 'は16進数のカラーコード（例：#FF0000）で指定してください' }, allow_blank: true, length: { maximum: 7, message: '表示色は7文字以内で入力してください' }
  validates :description, length: { maximum: 200, message: '説明は200文字以内で入力してください' }

  scope :active, -> { where(is_active: true) }
  scope :ordered, -> { order(display_order: :asc) }

  def self.default_status
    active.ordered.first
  end

  def to_s
    name
  end
end 
