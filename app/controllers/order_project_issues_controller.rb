class OrderProjectIssuesController < ApplicationController
  before_action :set_order
  before_action :set_issue, only: [:update, :destroy]

  def create
    @issue = @order.project_issues.build(issue_params.merge(company: current_company))
    if @issue.save
      redirect_to project_management_path(@order, anchor: "issues"), notice: "課題を追加しました"
    else
      redirect_to project_management_path(@order, anchor: "issues"), alert: @issue.errors.full_messages.join("、")
    end
  end

  def update
    if @issue.update(issue_params)
      redirect_to project_management_path(@order, anchor: "issues"), notice: "課題を更新しました"
    else
      redirect_to project_management_path(@order, anchor: "issues"), alert: @issue.errors.full_messages.join("、")
    end
  end

  def destroy
    @issue.destroy!
    redirect_to project_management_path(@order, anchor: "issues"), notice: "課題を削除しました"
  end

  private

  def set_order
    @order = current_company.orders.with_discarded.find(params[:order_id])
  end

  def set_issue
    @issue = @order.project_issues.find(params[:id])
  end

  def issue_params
    params.require(:order_project_issue).permit(:title, :description, :status, :priority, :due_date, :assignee_id)
  end
end
