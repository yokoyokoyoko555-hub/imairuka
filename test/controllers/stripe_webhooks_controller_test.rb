require "test_helper"

class StripeWebhooksControllerTest < ActionDispatch::IntegrationTest
  setup do
    @webhook_secret = ENV.delete("STRIPE_WEBHOOK_SECRET")
    @company = Company.create!(
      name: "Webhook Test Company",
      invoice_number: "T1234567890123",
      postal_code: "1000001",
      address: "Tokyo",
      phone: "0312345678",
      email: "webhook-company@example.com",
      representative: "Owner",
      business_type: "software",
      tenant_slug: "webhook-test-company",
      contract_status: "active",
      stripe_account_id: "acct_webhook_test"
    )
    Current.company = @company
    @customer = Customer.create!(
      company: @company,
      code: "C-WEBHOOK",
      name: "Webhook Customer",
      company_name: "Webhook Customer Inc",
      industry: "software",
      status: "active"
    )
    @status = OrderStatus.create!(
      company: @company,
      name: "Webhook New",
      code: "webhook_new",
      display_order: 1
    )
    @product = Product.create!(
      company: @company,
      code: "P-WEBHOOK",
      name: "Webhook Product",
      unit_price: 10_000
    )
    @order = Order.create!(
      company: @company,
      customer: @customer,
      order_status: @status,
      order_date: Date.current,
      staff_name: "Tester",
      total_amount: 10_000,
      order_items_attributes: {
        "0" => {
          product_id: @product.id,
          quantity: 1
        }
      }
    )
  end

  teardown do
    ENV["STRIPE_WEBHOOK_SECRET"] = @webhook_secret if @webhook_secret
    Current.company = nil
  end

  test "payment intent succeeded webhook saves payment history" do
    post "/stripe/webhook", params: {
      id: "evt_payment_intent_succeeded",
      type: "payment_intent.succeeded",
      data: {
        object: {
          id: "pi_webhook_succeeded",
          object: "payment_intent",
          amount: 10_000,
          amount_received: 10_000,
          currency: "jpy",
          created: Time.current.to_i,
          latest_charge: "ch_webhook_succeeded",
          metadata: {
            order_id: @order.id,
            company_id: @company.id
          },
          transfer_data: {
            destination: @company.stripe_account_id
          }
        }
      }
    }.to_json, headers: { "CONTENT_TYPE" => "application/json" }

    assert_response :success

    payment = @order.payment_records.find_by!(stripe_payment_intent_id: "pi_webhook_succeeded")
    assert_equal @company, payment.company
    assert_equal @company.stripe_account_id, payment.stripe_account_id
    assert_equal "ch_webhook_succeeded", payment.stripe_charge_id
    assert_equal "paid", payment.status
    assert_equal 10_000, payment.amount
    assert_equal Date.current, @order.reload.payment_date
  end

  test "account updated webhook syncs connect status" do
    post "/stripe/webhook", params: {
      id: "evt_account_updated",
      type: "account.updated",
      data: {
        object: {
          id: @company.stripe_account_id,
          object: "account",
          charges_enabled: true,
          payouts_enabled: true,
          details_submitted: true
        }
      }
    }.to_json, headers: { "CONTENT_TYPE" => "application/json" }

    assert_response :success

    @company.reload
    assert @company.stripe_charges_enabled?
    assert @company.stripe_payouts_enabled?
    assert @company.stripe_details_submitted?
    assert @company.stripe_onboarded_at.present?
  end
end
