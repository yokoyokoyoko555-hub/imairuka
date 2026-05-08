class CreatePaymentRecords < ActiveRecord::Migration[8.0]
  def change
    create_table :payment_records do |t|
      t.references :order, null: false, foreign_key: true
      t.references :company, null: true, foreign_key: true
      t.string :stripe_account_id
      t.string :stripe_checkout_session_id
      t.string :stripe_payment_intent_id
      t.string :stripe_charge_id
      t.string :stripe_event_id
      t.string :status, null: false, default: "pending"
      t.integer :amount, null: false, default: 0
      t.string :currency, null: false, default: "jpy"
      t.string :payment_method_type
      t.datetime :paid_at

      t.timestamps
    end

    add_index :payment_records, :stripe_checkout_session_id, unique: true
    add_index :payment_records, :stripe_payment_intent_id
    add_index :payment_records, :stripe_event_id
    add_index :payment_records, :status
    add_index :payment_records, :paid_at
  end
end
