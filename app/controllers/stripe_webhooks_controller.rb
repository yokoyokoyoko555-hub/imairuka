class StripeWebhooksController < ApplicationController
  skip_before_action :verify_authenticity_token
  skip_before_action :require_login
  skip_before_action :set_current_context
  skip_before_action :set_company_info

  def create
    event = build_event
    return head :bad_request unless event

    case event.type
    when "checkout.session.completed"
      handle_checkout_session_completed(event)
    when "checkout.session.expired"
      handle_checkout_session_expired(event)
    when "payment_intent.succeeded"
      handle_payment_intent_succeeded(event)
    when "payment_intent.payment_failed"
      handle_payment_intent_failed(event)
    when "account.updated"
      handle_account_updated(event)
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
    order_id = metadata_value(session.metadata, :order_id)
    return unless order_id.present?

    order = Order.find_by(id: order_id)
    return unless order

    payment = order.payment_records.find_or_initialize_by(stripe_checkout_session_id: session.id)
    payment.company ||= Company.find_by(id: metadata_value(session.metadata, :company_id))
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

  def handle_payment_intent_succeeded(event)
    upsert_payment_intent_record(event.data.object, event.id, "paid")
  end

  def handle_payment_intent_failed(event)
    upsert_payment_intent_record(event.data.object, event.id, "failed")
  end

  def handle_account_updated(event)
    account = event.data.object
    company = Company.find_by(stripe_account_id: account.id)
    return unless company

    company.update!(
      stripe_charges_enabled: truthy_stripe_value(account, :charges_enabled),
      stripe_payouts_enabled: truthy_stripe_value(account, :payouts_enabled),
      stripe_details_submitted: truthy_stripe_value(account, :details_submitted),
      stripe_onboarded_at: truthy_stripe_value(account, :details_submitted) ? (company.stripe_onboarded_at || Time.current) : company.stripe_onboarded_at
    )
  end

  def handle_checkout_session_expired(event)
    session = event.data.object
    payment = PaymentRecord.find_by(stripe_checkout_session_id: session.id)
    payment&.update!(status: "canceled", stripe_event_id: event.id)
  end

  def upsert_payment_intent_record(intent, event_id, status)
    order = order_for_payment_intent(intent)
    return unless order

    company = company_for_payment_intent(intent, order)
    payment = PaymentRecord.find_or_initialize_by(stripe_payment_intent_id: intent.id)
    payment.order ||= order
    payment.company ||= company
    payment.stripe_account_id ||= connected_account_id(intent, company)
    payment.stripe_charge_id = stripe_id(stripe_value(intent, :latest_charge))
    payment.stripe_event_id = event_id
    payment.status = status
    payment.amount = payment_intent_amount(intent, order)
    payment.currency = stripe_value(intent, :currency).presence || "jpy"
    payment.payment_method_type ||= "card"

    if status == "paid"
      payment.paid_at ||= Time.zone.at(stripe_value(intent, :created)) if stripe_value(intent, :created).present?
      payment.paid_at ||= Time.current
    end

    payment.save!
    order.update!(payment_date: payment.paid_at.to_date) if payment.paid? && payment.paid_at.present? && order.payment_date.blank?
  end

  def order_for_payment_intent(intent)
    metadata_order_id = metadata_value(stripe_value(intent, :metadata), :order_id)
    return Order.find_by(id: metadata_order_id) if metadata_order_id.present?

    PaymentRecord.find_by(stripe_payment_intent_id: intent.id)&.order
  end

  def company_for_payment_intent(intent, order)
    metadata_company_id = metadata_value(stripe_value(intent, :metadata), :company_id)
    Company.find_by(id: metadata_company_id) || order.company
  end

  def connected_account_id(intent, company)
    transfer_data = stripe_value(intent, :transfer_data)
    stripe_value(transfer_data, :destination).presence || company&.stripe_account_id
  end

  def payment_intent_amount(intent, order)
    stripe_value(intent, :amount_received).presence ||
      stripe_value(intent, :amount).presence ||
      order.total_amount
  end

  def stripe_id(value)
    value.respond_to?(:id) ? value.id : value
  end

  def metadata_value(metadata, key)
    return if metadata.blank?

    metadata[key.to_s] || metadata[key.to_sym] if metadata.respond_to?(:[])
  end

  def stripe_value(object, key)
    return if object.blank?
    return object.public_send(key) if object.respond_to?(key)
    return object[key.to_s] if object.respond_to?(:[])

    nil
  end

  def truthy_stripe_value(object, key)
    ActiveModel::Type::Boolean.new.cast(stripe_value(object, key))
  end
end
