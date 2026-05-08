class PaymentHistoriesController < ApplicationController
  def index
    @payments = Order.includes(:customer, :order_status).order(created_at: :desc)

    if params[:order_number].present?
      @payments = @payments.where("order_number LIKE ?", "%#{params[:order_number]}%")
    end

    if params[:customer_name].present?
      @payments = @payments.joins(:customer).where("customers.name LIKE ?", "%#{params[:customer_name]}%")
    end

    if params[:payment_status].present?
      @payments = params[:payment_status] == "paid" ? @payments.where.not(payment_date: nil) : @payments.where(payment_date: nil)
    end

    if params[:payment_date_from].present?
      @payments = @payments.where("payment_date >= ?", params[:payment_date_from])
    end

    if params[:payment_date_to].present?
      @payments = @payments.where("payment_date <= ?", params[:payment_date_to])
    end

    @payments = @payments.page(params[:page]).per(20)
  end
end
