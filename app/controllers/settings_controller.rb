class SettingsController < ApplicationController
  def index
    @company = current_company || Company.first_or_initialize
    sync_stripe_account_status if params[:tab] == "stripe" && StripeSettings.connect_mode? && @company.stripe_account_id.present? && StripeSettings.configured?

    if params[:tab] == "status"
      @order_statuses = OrderStatus.active.ordered
    end
  end

  def update
    @company = current_company || Company.first_or_initialize

    if @company.update(company_params)
      flash[:success] = "設定を保存しました"
      redirect_to settings_path(tab: params[:tab])
    else
      @order_statuses = OrderStatus.active.ordered if params[:tab] == "status"
      render :index, status: :unprocessable_entity
    end
  end

  private

  def sync_stripe_account_status
    account = Stripe::Account.retrieve(@company.stripe_account_id)
    @company.update!(
      stripe_charges_enabled: account.charges_enabled,
      stripe_payouts_enabled: account.payouts_enabled,
      stripe_details_submitted: account.details_submitted,
      stripe_onboarded_at: account.details_submitted ? (@company.stripe_onboarded_at || Time.current) : @company.stripe_onboarded_at
    )
  rescue Stripe::StripeError => e
    Rails.logger.error("Stripe Connect status sync error: #{e.message}")
    flash.now[:alert] = "Stripe連携状態を取得できませんでした。"
  end

  def company_params
    params.require(:company).permit(
      :name,
      :invoice_number,
      :postal_code,
      :address,
      :phone,
      :email,
      :representative,
      :business_type,
      :ai_provider,
      :ai_model,
      :ai_api_key,
      :clear_ai_api_key
    )
  end
end
