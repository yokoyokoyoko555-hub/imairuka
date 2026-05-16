class SignupController < ApplicationController
  layout "signup"

  skip_before_action :require_login
  skip_before_action :set_current_context
  skip_before_action :set_company_info

  def new
    @company = Company.new(
      contract_status: "pending_review",
      plan_name: Company::DEFAULT_PLAN_NAME,
      sales_channel: "direct",
      billing_status: "unbilled",
      contract_amount: Company::DEFAULT_CONTRACT_AMOUNT,
      contract_months: Company::DEFAULT_CONTRACT_MONTHS
    )
  end

  def create
    @company = Company.new(signup_params)
    apply_vendor_code
    @company.assign_attributes(
      contract_status: "pending_review",
      plan_name: Company::DEFAULT_PLAN_NAME,
      billing_status: "unbilled",
      contract_amount: Company::DEFAULT_CONTRACT_AMOUNT,
      contract_months: Company::DEFAULT_CONTRACT_MONTHS
    )

    if @company.errors.any?
      render :new, status: :unprocessable_entity
      return
    end

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

  def apply_vendor_code
    code = params.dig(:company, :vendor_code).to_s.strip
    return if code.blank?

    vendor = Vendor.active.find_by("UPPER(code) = ?", code.upcase)
    if vendor
      @company.vendor = vendor
      @company.sales_channel = "vendor"
      @company.billing_payer_type = "vendor"
    else
      @company.errors.add(:vendor_code, "が見つかりません。紹介元に確認してください。")
    end
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
      :business_type,
      :vendor_code
    )
  end
end
