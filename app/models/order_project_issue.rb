class OrderProjectIssue < ApplicationRecord
  include TenantScoped

  belongs_to :company
  belongs_to :order
  belongs_to :assignee, class_name: "User", optional: true

  enum :status, {
    open: "open",
    in_progress: "in_progress",
    resolved: "resolved",
    closed: "closed"
  }, default: "open"

  enum :priority, {
    low: "low",
    normal: "normal",
    high: "high",
    urgent: "urgent"
  }, default: "normal"

  validates :title, presence: true, length: { maximum: 120 }
  validates :description, length: { maximum: 1000 }
  validate :assignee_belongs_to_company

  scope :ordered, -> { order(Arel.sql("CASE status WHEN 'open' THEN 0 WHEN 'in_progress' THEN 1 WHEN 'resolved' THEN 2 ELSE 3 END"), :due_date, :id) }

  before_save :set_resolved_at

  def status_label
    {
      "open" => "未対応",
      "in_progress" => "対応中",
      "resolved" => "解決済み",
      "closed" => "クローズ"
    }.fetch(status, status)
  end

  def priority_label
    OrderProjectTask.new(priority: priority).priority_label
  end

  private

  def assignee_belongs_to_company
    return if assignee.blank? || assignee.company_id == company_id

    errors.add(:assignee, "は同じ会社のユーザーを選択してください")
  end

  def set_resolved_at
    self.resolved_at = Time.current if resolved? && resolved_at.blank?
    self.resolved_at = nil if !resolved? && status_changed?
  end
end
