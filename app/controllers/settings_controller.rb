class SettingsController < ApplicationController
  def index
    # 会社情報の取得
    @company = Company.first_or_initialize
    sync_stripe_account_status if params[:tab] == "stripe" && StripeSettings.connect_mode? && @company.stripe_account_id.present? && StripeSettings.configured?

    # ステータス情報の取得
    if params[:tab] == 'status'
      @order_statuses = OrderStatus.active.ordered
    end
  end

  def update
    @company = Company.first_or_initialize

    if @company.new_record?
      @company.assign_attributes(company_params)

      if @company.save
        flash[:success] = "会社情報を登録しました"
        redirect_to settings_path(tab: params[:tab])
      else
        @order_statuses = OrderStatus.active.ordered if params[:tab] == 'status'
        render :index, status: :unprocessable_entity
      end
    else
      if @company.update(company_params)
        flash[:success] = "会社情報を更新しました"
        redirect_to settings_path(tab: params[:tab])
      else
        @order_statuses = OrderStatus.active.ordered if params[:tab] == 'status'
        render :index, status: :unprocessable_entity
      end
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
    params.require(:company).permit(:name, :invoice_number, :postal_code, :address, :phone, :email, :representative, :business_type)
  end
end 
