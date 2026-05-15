module Account
  class BillingController < ApplicationController
    before_action -> { require_role!(:platform_admin, :owner, :admin) }

    def add_user_slot
      unless current_company.account_invitation_unlocked?
        redirect_to account_users_path, alert: current_company.user_limit_message
        return
      end

      unless StripeSettings.configured?
        redirect_to account_users_path, alert: "Stripe本番キーが未設定のため、追加アカウント課金を開始できません。"
        return
      end

      session = Stripe::Checkout::Session.create(checkout_session_params)
      redirect_to session.url, allow_other_host: true
    rescue Stripe::StripeError => e
      Rails.logger.error("Additional user checkout error: #{e.message}")
      redirect_to account_users_path, alert: "追加アカウント課金の開始に失敗しました。時間をおいて再度お試しください。"
    end

    private

    def checkout_session_params
      {
        mode: "subscription",
        customer: current_company.stripe_customer_id.presence,
        customer_email: current_company.stripe_customer_id.present? ? nil : current_company.email,
        line_items: [line_item],
        success_url: "#{account_users_url}?account_addon=success",
        cancel_url: "#{account_users_url}?account_addon=cancel",
        metadata: {
          purpose: "account_addon",
          company_id: current_company.id,
          additional_user_slots: 1
        },
        subscription_data: {
          metadata: {
            purpose: "account_addon",
            company_id: current_company.id,
            additional_user_slots: 1
          }
        }
      }.compact
    end

    def line_item
      if ENV["STRIPE_ADDITIONAL_USER_PRICE_ID"].present?
        { price: ENV.fetch("STRIPE_ADDITIONAL_USER_PRICE_ID"), quantity: 1 }
      else
        {
          price_data: {
            currency: "jpy",
            recurring: { interval: "month" },
            product_data: { name: "Imairuka 追加アカウント 1名" },
            unit_amount: current_company.additional_user_monthly_amount
          },
          quantity: 1
        }
      end
    end
  end
end
