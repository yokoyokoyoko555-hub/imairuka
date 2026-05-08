class AddMissingFieldsToReceipts < ActiveRecord::Migration[8.0]
  def change
    add_column :receipts, :customer_address, :string unless column_exists?(:receipts, :customer_address)
    add_column :receipts, :subject, :string unless column_exists?(:receipts, :subject)
  end
end
