class AddRefundFieldsToPaymentRecords < ActiveRecord::Migration[8.0]
  def change
    add_column :payment_records, :refunded_at, :datetime
    add_column :payment_records, :refunded_amount, :integer

    add_index :payment_records, :refunded_at
  end
end
