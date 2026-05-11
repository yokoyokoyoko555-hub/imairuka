class OrderAssignmentsController < ApplicationController
  before_action :set_order
  before_action :set_assignment, only: [:update, :destroy]

  def create
    @assignment = @order.assignments.build(assignment_params.merge(company: current_company))
    if @assignment.save
      redirect_to @order, notice: "アサインを追加しました"
    else
      redirect_to @order, alert: @assignment.errors.full_messages.join("、")
    end
  end

  def update
    if @assignment.update(assignment_params)
      redirect_to @order, notice: "アサインを更新しました"
    else
      redirect_to @order, alert: @assignment.errors.full_messages.join("、")
    end
  end

  def destroy
    @assignment.destroy!
    redirect_to @order, notice: "アサインを削除しました"
  end

  private

  def set_order
    @order = current_company.orders.with_discarded.find(params[:order_id])
  end

  def set_assignment
    @assignment = @order.assignments.find(params[:id])
  end

  def assignment_params
    params.require(:order_assignment).permit(:user_id, :role, :note)
  end
end
