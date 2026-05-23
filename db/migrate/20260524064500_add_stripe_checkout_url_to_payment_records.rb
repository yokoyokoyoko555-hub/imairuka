class AddStripeCheckoutUrlToPaymentRecords < ActiveRecord::Migration[8.0]
  def change
    add_column :payment_records, :stripe_checkout_url, :text
  end
end
