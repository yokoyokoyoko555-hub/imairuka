class OrderProjectTasksController < ApplicationController
  before_action :set_order
  before_action :set_task, only: [:update, :destroy]

  def create
    @task = @order.project_tasks.build(task_params.merge(company: current_company))
    @task.position ||= @order.project_tasks.maximum(:position).to_i + 1
    if @task.save
      redirect_to @order, notice: "タスクを追加しました"
    else
      redirect_to @order, alert: @task.errors.full_messages.join("、")
    end
  end

  def update
    if @task.update(task_params)
      redirect_to @order, notice: "タスクを更新しました"
    else
      redirect_to @order, alert: @task.errors.full_messages.join("、")
    end
  end

  def destroy
    @task.destroy!
    redirect_to @order, notice: "タスクを削除しました"
  end

  private

  def set_order
    @order = current_company.orders.with_discarded.find(params[:order_id])
  end

  def set_task
    @task = @order.project_tasks.find(params[:id])
  end

  def task_params
    params.require(:order_project_task).permit(:title, :description, :status, :priority, :start_date, :due_date, :assignee_id)
  end
end
