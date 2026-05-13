class SignupController < ApplicationController
  layout "signup"

  skip_before_action :require_login
  skip_before_action :set_current_context
  skip_before_action :set_company_info

  def new
    @company = Company.new(contract_status: "pending_review", plan_name: Company::DEFAULT_PLAN_NAME)
  end

  def create
    @company = Company.new(signup_params)
    @company.assign_attributes(
      contract_status: "pending_review",
      plan_name: Company::DEFAULT_PLAN_NAME
    )

    if @company.save
      redirect_to signup_complete_path, notice: "利用申込を受け付けました。"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def complete
  end

  private

  def signup_params
    params.require(:company).permit(
      :name,
      :invoice_number,
      :postal_code,
      :address,
      :phone,
      :email,
      :representative,
      :business_type
    )
  end
end
