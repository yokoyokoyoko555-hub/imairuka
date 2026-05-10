module Admin
  class CompaniesController < ApplicationController
    before_action -> { require_role!(:platform_admin) }

    def index
      @companies = Company.order(created_at: :desc)
    end

    def show
      @company = Company.find(params[:id])
      @users = User.where(company: @company).order(:email)
      @orders_count = Order.unscoped.where(company: @company).count
      @payments_count = PaymentRecord.unscoped.where(company: @company).count
    end
  end
end
