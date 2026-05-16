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

    if duplicate_pending_signup?
      @company.errors.add(:email, "は既に利用申込を受付中です。運営からの案内をお待ちください。")
      render :new, status: :unprocessable_entity
      return
    end

    if @company.save
      redirect_to signup_complete_path, notice: "利用申込を受け付けました。"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def complete
  end

  private

  def duplicate_pending_signup?
    email = signup_params[:email].to_s.strip.downcase
    name = signup_params[:name].to_s.strip
    Company.pending_review.where("LOWER(email) = ? OR name = ?", email, name).exists?
  end

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
