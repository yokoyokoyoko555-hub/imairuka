class StripeWebhooksController < ApplicationController
  skip_before_action :verify_authenticity_token
  skip_before_action :require_login
  skip_before_action :set_company_info

  def create
    event = build_event
    return head :bad_request unless event

    case event.type
    when "checkout.session.completed"
      handle_checkout_session_completed(event)
    when "checkout.session.expired"
      handle_checkout_session_expired(event)
    end

    head :ok
  rescue => e
    Rails.logger.error("Stripe webhook error: #{e.class}: #{e.message}")
    head :bad_request
  end

  private

  def build_event
    payload = request.raw_post
    webhook_secret = ENV["STRIPE_WEBHOOK_SECRET"]

    if webhook_secret.present?
      Stripe::Webhook.construct_event(payload, request.env["HTTP_STRIPE_SIGNATURE"], webhook_secret)
    else
      Stripe::Event.construct_from(JSON.parse(payload))
    end
  rescue JSON::ParserError, Stripe::SignatureVerificationError => e
    Rails.logger.warn("Stripe webhook verification failed: #{e.message}")
    nil
  end

  def handle_checkout_session_completed(event)
    session = event.data.object
    if session.metadata&.purpose == "account_addon"
      handle_account_addon_completed(event, session)
      return
    end

    return unless session.metadata&.order_id.present?

    order = Order.find_by(id: session.metadata.order_id)
    return unless order

    payment = order.payment_records.find_or_initialize_by(stripe_checkout_session_id: session.id)
    payment.company ||= Company.find_by(id: session.metadata.company_id)
    payment.stripe_account_id ||= StripeSettings.connect_mode? ? payment.company&.stripe_account_id : nil
    payment.stripe_payment_intent_id = stripe_id(session.payment_intent)
    payment.stripe_event_id = event.id
    payment.status = session.payment_status == "paid" ? "paid" : "pending"
    payment.amount = session.amount_total || order.total_amount
    payment.currency = session.currency || "jpy"
    payment.payment_method_type ||= Array(session.payment_method_types).first || "card"
    payment.paid_at ||= Time.zone.at(session.created) if payment.paid? && session.created.present?
    payment.paid_at ||= Time.current if payment.paid?
    payment.save!

    order.update!(payment_date: payment.paid_at.to_date) if payment.paid? && order.payment_date.blank?
  end

  def handle_checkout_session_expired(event)
    session = event.data.object
    return if session.metadata&.purpose == "account_addon"

    payment = PaymentRecord.find_by(stripe_checkout_session_id: session.id)
    payment&.update!(status: "canceled", stripe_event_id: event.id)
  end

  def handle_account_addon_completed(event, session)
    company = Company.find_by(id: session.metadata.company_id)
    return unless company

    additional_slots = session.metadata.additional_user_slots.to_i
    additional_slots = 1 if additional_slots < 1

    company.with_lock do
      company.additional_user_slots = company.additional_user_slots.to_i + additional_slots
      company.stripe_customer_id ||= stripe_id(session.customer)
      company.stripe_additional_users_subscription_id = stripe_id(session.subscription)
      company.stripe_additional_users_subscription_status = "active"
      company.save!
    end
  end

  def stripe_id(value)
    value.respond_to?(:id) ? value.id : value
  end
end
