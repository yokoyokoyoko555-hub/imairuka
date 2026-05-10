module Admin
  class CompaniesController < ApplicationController
    before_action -> { require_role!(:platform_admin) }

    def index
      @companies = Company.order(created_at: :desc)
    end

    def new
      @company = Company.new(
        contract_status: "trialing",
        plan_name: "standard",
        trial_ends_at: 14.days.from_now
      )
      @owner = User.new(role: "owner", active: true)
    end

    def create
      @company = Company.new(company_params)
      @owner = @company.users.build(owner_params.merge(role: "owner", active: true))

      if @company.save
        redirect_to admin_company_path(@company), notice: "新しい契約を追加しました。"
      else
        render :new, status: :unprocessable_entity
      end
    end

    def show
      @company = Company.find(params[:id])
      @users = User.where(company: @company).order(:email)
      @orders_count = Order.unscoped.where(company: @company).count
      @payments_count = PaymentRecord.unscoped.where(company: @company).count
    end

    private

    def company_params
      params.require(:company).permit(
        :name,
        :tenant_slug,
        :invoice_number,
        :postal_code,
        :address,
        :phone,
        :email,
        :representative,
        :business_type,
        :contract_status,
        :plan_name,
        :trial_ends_at
      )
    end

    def owner_params
      params.require(:owner).permit(:name, :email, :password, :password_confirmation)
    end
  end
end
