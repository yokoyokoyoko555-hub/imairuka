class PublicPaymentsController < ApplicationController
  skip_before_action :require_login
  skip_before_action :ensure_current_company_available
  skip_before_action :prevent_read_only_write
  skip_before_action :set_current_context
  skip_before_action :set_company_info

  def success
    sync_payment_result if params[:session_id].present? && StripeSettings.configured?
    render_payment_page("お支払いが完了しました", "ご入金を確認しました。この画面は閉じていただいて問題ありません。")
  rescue Stripe::StripeError => e
    Rails.logger.error("Stripe payment confirmation error: #{e.message}")
    render_payment_page("支払い結果を確認中です", "決済結果の反映に少し時間がかかる場合があります。しばらくしてから再度ご確認ください。")
  end

  def cancel
    render_payment_page("支払いはキャンセルされました", "必要に応じて、送付された決済リンクから再度お支払いください。")
  end

  private

  def sync_payment_result
    session = Stripe::Checkout::Session.retrieve(params[:session_id])
    return unless session.payment_status == "paid" && session.metadata&.order_id.present?

    company = Company.find_by(id: session.metadata.company_id)
    order = company&.orders&.find_by(id: session.metadata.order_id)
    return unless order

    payment = order.payment_records.find_by(stripe_payment_intent_id: session.payment_intent) if session.payment_intent.present?
    payment ||= order.payment_records.find_by(stripe_checkout_session_id: session.id)
    payment ||= order.payment_records.pending.where.not(stripe_checkout_url: [nil, ""]).order(created_at: :desc).first
    payment ||= order.payment_records.build

    payment.company ||= company
    payment.stripe_account_id ||= StripeSettings.connect_mode? ? company.stripe_account_id : nil
    payment.stripe_payment_intent_id ||= session.payment_intent
    payment.stripe_checkout_session_id ||= session.id
    payment.stripe_checkout_url ||= session.url if session.respond_to?(:url) && session.url.present?
    payment.status = "paid"
    payment.amount = session.amount_total || order.total_amount
    payment.currency = session.currency || "jpy"
    payment.payment_method_type ||= "card"
    payment.paid_at ||= Time.current
    payment.save!

    order.update!(payment_date: payment.paid_at.to_date) if order.payment_date.blank?
    order.payment_records.pending.where.not(id: payment.id).update_all(status: "canceled", updated_at: Time.current)
  end

  def render_payment_page(title, body)
    render html: payment_page_html(title, body).html_safe
  end

  def payment_page_html(title, body)
    escaped_title = ERB::Util.html_escape(title)
    escaped_body = ERB::Util.html_escape(body)

    <<~HTML
      <!doctype html>
      <html lang="ja">
        <head>
          <meta charset="utf-8">
          <meta name="viewport" content="width=device-width, initial-scale=1">
          <title>#{escaped_title}</title>
          <style>
            body { margin: 0; min-height: 100vh; display: grid; place-items: center; font-family: system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif; background: #f3f4f6; color: #111827; }
            main { width: min(92vw, 560px); background: #fff; border: 1px solid #e5e7eb; border-radius: 8px; padding: 32px; box-shadow: 0 16px 40px rgba(15, 23, 42, .08); }
            .brand { font-weight: 700; color: #0d6efd; margin-bottom: 20px; }
            h1 { font-size: 28px; margin: 0 0 12px; }
            p { font-size: 16px; line-height: 1.8; margin: 0; color: #4b5563; }
          </style>
        </head>
        <body>
          <main>
            <div class="brand">Imairuka</div>
            <h1>#{escaped_title}</h1>
            <p>#{escaped_body}</p>
          </main>
        </body>
      </html>
    HTML
  end
end
