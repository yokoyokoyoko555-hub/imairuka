class PaymentHistoriesController < ApplicationController
  def index
    @payments = PaymentRecord.includes(order: [:customer, :order_status]).order(created_at: :desc)

    if params[:order_number].present?
      @payments = @payments.joins(:order).where("orders.order_number LIKE ?", "%#{params[:order_number]}%")
    end

    if params[:customer_name].present?
      @payments = @payments.joins(order: :customer).where("customers.name LIKE ?", "%#{params[:customer_name]}%")
    end

    if params[:payment_status].present?
      @payments = @payments.where(status: params[:payment_status])
    end

    if params[:payment_date_from].present?
      @payments = @payments.where("paid_at >= ?", Time.zone.parse(params[:payment_date_from]).beginning_of_day)
    end

    if params[:payment_date_to].present?
      @payments = @payments.where("paid_at <= ?", Time.zone.parse(params[:payment_date_to]).end_of_day)
    end

    @payments = @payments.page(params[:page]).per(20)
  end
end
