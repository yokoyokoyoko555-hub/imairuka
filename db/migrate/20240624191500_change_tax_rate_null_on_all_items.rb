class ChangeTaxRateNullOnAllItems < ActiveRecord::Migration[6.0]
  def change
    change_column_null :invoice_items, :tax_rate, true
    change_column_null :quotation_items, :tax_rate, true
    change_column_null :delivery_note_items, :tax_rate, true
    change_column_null :receipt_items, :tax_rate, true
  end
end 