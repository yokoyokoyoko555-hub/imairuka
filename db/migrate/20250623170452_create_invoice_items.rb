class CreateInvoiceItems < ActiveRecord::Migration[8.0]
  def change
    create_table :invoice_items do |t|
      t.references :invoice, null: false, foreign_key: true
      t.string :product_code, null: false
      t.string :product_name, null: false
      t.integer :unit_price, null: false, default: 0
      t.integer :quantity, null: false, default: 1
      t.integer :tax_rate, null: false, default: 1
      t.integer :amount, null: false, default: 0

      t.timestamps
    end
    
    add_index :invoice_items, :product_code
    add_index :invoice_items, :tax_rate
  end
end
