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

    if parsed_payment_date_from
      @payments = @payments.where("paid_at >= ?", parsed_payment_date_from.beginning_of_day)
    end

    if parsed_payment_date_to
      @payments = @payments.where("paid_at <= ?", parsed_payment_date_to.end_of_day)
    end

    @payments = @payments.page(params[:page]).per(20)
  end

  private

  def parsed_payment_date_from
    @parsed_payment_date_from ||= parse_date_param(:payment_date_from)
  end

  def parsed_payment_date_to
    @parsed_payment_date_to ||= parse_date_param(:payment_date_to)
  end

  def parse_date_param(key)
    return if params[key].blank?

    Time.zone.parse(params[key])
  rescue ArgumentError, TypeError
    nil
  end
end
