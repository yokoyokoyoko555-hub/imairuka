class OrderHistory < ApplicationRecord
  belongs_to :order
  # userは文字列フィールドとして扱うため、アソシエーションを削除

  validates :action, presence: true
  validates :description, presence: true
  validates :staff_name, presence: true

  enum :action, {
    created: 'created',
    updated: 'updated',
    status_changed: 'status_changed',
    payment_status_changed: 'payment_status_changed',
    delivery_status_changed: 'delivery_status_changed',
    billing_status_changed: 'billing_status_changed'
  }

  def self.record_change(order, staff_name, action, description)
    create!(
      order: order,
      staff_name: staff_name,
      action: action,
      description: description
    )
  end
end 