class OrderProjectTasksController < ApplicationController
  before_action :set_order
  before_action :set_task, only: [:update, :destroy]

  def create
    @task = @order.project_tasks.build(task_params.merge(company: current_company))
    @task.position ||= next_position(@task.parent_id)

    if @task.save
      redirect_to project_management_path(@order, anchor: "project-management"), notice: "タスクを追加しました"
    else
      redirect_to project_management_path(@order, anchor: "project-management"), alert: @task.errors.full_messages.join("、")
    end
  end

  def update
    if @task.update(task_params)
      redirect_to project_management_path(@order, anchor: "project-management"), notice: "タスクを更新しました"
    else
      redirect_to project_management_path(@order, anchor: "project-management"), alert: @task.errors.full_messages.join("、")
    end
  end

  def destroy
    @task.destroy!
    redirect_to project_management_path(@order, anchor: "project-management"), notice: "タスクを削除しました"
  end

  private

  def set_order
    @order = current_company.orders.with_discarded.find(params[:order_id])
  end

  def set_task
    @task = @order.project_tasks.find(params[:id])
  end

  def next_position(parent_id)
    @order.project_tasks.where(parent_id: parent_id.presence).maximum(:position).to_i + 1
  end

  def task_params
    params.require(:order_project_task).permit(:parent_id, :title, :description, :status, :priority, :start_date, :due_date, :assignee_id)
  end
end
