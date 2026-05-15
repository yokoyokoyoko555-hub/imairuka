class StripeConnectController < ApplicationController
  before_action :set_company

  def create
    unless StripeSettings.connect_mode?
      redirect_to settings_path(tab: "stripe"), alert: "直接決済モードではStripe Connect連携は不要です。"
      return
    end

    unless stripe_configured?
      redirect_to settings_path(tab: "stripe"), alert: "Stripe platform key is not configured."
      return
    end

    unless @company.persisted?
      redirect_to settings_path(tab: "company"), alert: "Stripe連携の前に会社情報を保存してください。"
      return
    end

    ensure_connected_account!
    redirect_to onboarding_url, allow_other_host: true
  rescue Stripe::StripeError => e
    Rails.logger.error("Stripe Connect onboarding error: #{e.message}")
    redirect_to settings_path(tab: "stripe"), alert: stripe_error_message(e, fallback: "Stripe連携の開始に失敗しました。")
  end

  def refresh
    unless StripeSettings.connect_mode?
      redirect_to settings_path(tab: "stripe"), alert: "直接決済モードではStripe Connect連携は不要です。"
      return
    end

    unless stripe_configured?
      redirect_to settings_path(tab: "stripe"), alert: "Stripe platform key is not configured."
      return
    end

    unless @company.persisted?
      redirect_to settings_path(tab: "company"), alert: "Stripe連携の前に会社情報を保存してください。"
      return
    end

    ensure_connected_account!
    redirect_to onboarding_url, allow_other_host: true
  rescue Stripe::StripeError => e
    Rails.logger.error("Stripe Connect refresh error: #{e.message}")
    redirect_to settings_path(tab: "stripe"), alert: stripe_error_message(e, fallback: "Stripe連携リンクの再作成に失敗しました。")
  end

  def callback
    sync_account_status if stripe_configured? && @company.stripe_account_id.present?
    redirect_to settings_path(tab: "stripe"), notice: "Stripe連携情報を更新しました。"
  rescue Stripe::StripeError => e
    Rails.logger.error("Stripe Connect callback error: #{e.message}")
    redirect_to settings_path(tab: "stripe"), alert: "Stripe連携状態の確認に失敗しました。"
  end

  private

  def set_company
    @company = current_company
  end

  def stripe_configured?
    StripeSettings.configured?
  end

  def stripe_error_message(error, fallback:)
    if error.message.include?("signed up for Connect")
      "運営側のStripeアカウントでConnectの利用開始が完了していません。StripeダッシュボードのConnect設定を完了してから、もう一度連携してください。"
    else
      fallback
    end
  end

  def ensure_connected_account!
    return if @company.stripe_account_id.present?

    account = Stripe::Account.create(
      type: "standard",
      country: "JP",
      email: @company.email.presence,
      business_profile: {
        name: @company.name.presence || "Imairuka merchant"
      },
      metadata: {
        company_id: @company.id
      }
    )

    @company.update!(stripe_account_id: account.id)
  end

  def onboarding_url
    account_link = Stripe::AccountLink.create(
      account: @company.stripe_account_id,
      refresh_url: stripe_connect_refresh_url,
      return_url: stripe_connect_callback_url,
      type: "account_onboarding"
    )
    account_link.url
  end

  def sync_account_status
    account = Stripe::Account.retrieve(@company.stripe_account_id)
    @company.update!(
      stripe_charges_enabled: account.charges_enabled,
      stripe_payouts_enabled: account.payouts_enabled,
      stripe_details_submitted: account.details_submitted,
      stripe_onboarded_at: account.details_submitted ? Time.current : @company.stripe_onboarded_at
    )
  end
end
