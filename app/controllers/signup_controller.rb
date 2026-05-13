class SignupController < ApplicationController
  layout "signup"

  skip_before_action :require_login
  skip_before_action :set_current_context
  skip_before_action :set_company_info

  def new
    @company = Company.new(contract_status: "pending_review", plan_name: "standard")
  end

  def create
    @company = Company.new(signup_params.merge(contract_status: "pending_review"))

    if @company.save
      redirect_to new_signup_path, notice: "利用申込を受け付けました。運営側で確認後、利用開始のご案内をお送りします。"
    else
      render :new, status: :unprocessable_entity
    end
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
      :business_type,
      :plan_name
    )
  end
end
