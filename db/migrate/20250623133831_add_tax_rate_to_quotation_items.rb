class AddTaxRateToQuotationItems < ActiveRecord::Migration[8.0]
  def change
    add_column :quotation_items, :tax_rate, :integer
  end
end
