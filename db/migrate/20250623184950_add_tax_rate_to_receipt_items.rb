class AddTaxRateToReceiptItems < ActiveRecord::Migration[8.0]
  def change
    add_column :receipt_items, :tax_rate, :integer
  end
end
