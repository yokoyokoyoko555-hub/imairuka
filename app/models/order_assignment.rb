class OrderAssignment < ApplicationRecord
  include TenantScoped

  belongs_to :company
  belongs_to :order
  belongs_to :user

  enum :role, {
    owner: "owner",
    manager: "manager",
    member: "member",
    reviewer: "reviewer"
  }, default: "member"

  validates :user_id, uniqueness: { scope: :order_id }
  validates :note, length: { maximum: 500 }
  validate :user_belongs_to_company

  def role_label
    {
      "owner" => "責任者",
      "manager" => "進行管理",
      "member" => "担当",
      "reviewer" => "確認者"
    }.fetch(role, role)
  end

  private

  def user_belongs_to_company
    return if user.blank? || user.company_id == company_id

    errors.add(:user, "は同じ会社のユーザーを選択してください")
  end
end
