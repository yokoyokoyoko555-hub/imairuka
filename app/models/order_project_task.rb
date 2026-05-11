class OrderProjectTask < ApplicationRecord
  include TenantScoped

  belongs_to :company
  belongs_to :order
  belongs_to :assignee, class_name: "User", optional: true

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
  validate :date_range

  scope :ordered, -> { order(:position, :start_date, :due_date, :id) }

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

  def date_range
    return if start_date.blank? || due_date.blank? || start_date <= due_date

    errors.add(:due_date, "は開始日以降にしてください")
  end
end
