class OrderStatusesController < ApplicationController
  before_action :set_order_status, only: [:show, :edit, :update, :destroy]

  def index
    @order_statuses = OrderStatus.ordered.page(params[:page])
  end

  def show
  end

  def new
    max_display_order = OrderStatus.maximum(:display_order) || 0
    @order_status = OrderStatus.new(display_order: max_display_order + 1)
  end

  def edit
  end

  def create
    @order_status = OrderStatus.new(order_status_params)

    if @order_status.save
      redirect_to settings_path(tab: 'status'), notice: 'ステータスを登録しました'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @order_status.update(order_status_params)
      redirect_to settings_path(tab: 'status'), notice: 'ステータスを更新しました'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @order_status.orders.exists?
      redirect_to settings_path(tab: 'status'), alert: 'このステータスは使用中のため削除できません'
    else
      @order_status.destroy
      redirect_to settings_path(tab: 'status'), notice: 'ステータスを削除しました'
    end
  end

  private

  def set_order_status
    @order_status = OrderStatus.find(params[:id])
  end

  def order_status_params
    params.require(:order_status).permit(
      :name,
      :code,
      :display_order,
      :color,
      :description,
      :is_active
    )
  end
end 