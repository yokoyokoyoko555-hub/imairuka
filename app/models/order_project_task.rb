class OrderProjectTask < ApplicationRecord
  include TenantScoped

  belongs_to :company
  belongs_to :order
  belongs_to :assignee, class_name: "User", optional: true
  belongs_to :parent, class_name: "OrderProjectTask", optional: true
  has_many :subtasks, class_name: "OrderProjectTask", foreign_key: :parent_id, dependent: :nullify, inverse_of: :parent

  enum :status, {
    not_started: "not_started",
    in_progress: "in_progress",
    blocked: "blocked",
    done: "done"
  }, default: "not_started"

  enum :priority, {
    low: "low",
    normal: "normal",
    high: "high",
    urgent: "urgent"
  }, default: "normal"

  validates :title, presence: true, length: { maximum: 120 }
  validates :description, length: { maximum: 1000 }
  validate :assignee_belongs_to_company
  validate :parent_belongs_to_same_order
  validate :date_range

  scope :ordered, -> { order(:position, :start_date, :due_date, :id) }
  scope :phases, -> { where(parent_id: nil) }
  scope :details, -> { where.not(parent_id: nil) }

  def status_label
    {
      "not_started" => "未着手",
      "in_progress" => "進行中",
      "blocked" => "保留",
      "done" => "完了"
    }.fetch(status, status)
  end

  def priority_label
    {
      "low" => "低",
      "normal" => "通常",
      "high" => "高",
      "urgent" => "至急"
    }.fetch(priority, priority)
  end

  private

  def assignee_belongs_to_company
    return if assignee.blank? || assignee.company_id == company_id

    errors.add(:assignee, "は同じ会社のユーザーを選択してください")
  end

  def parent_belongs_to_same_order
    return if parent.blank?

    errors.add(:parent, "は同じ案件の工程を選択してください") if parent.order_id != order_id || parent.company_id != company_id
    errors.add(:parent, "に自分自身は指定できません") if parent_id == id
  end

  def date_range
    return if start_date.blank? || due_date.blank? || start_date <= due_date

    errors.add(:due_date, "は開始日以降にしてください")
  end
end
