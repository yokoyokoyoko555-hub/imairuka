class CreateQuotationItems < ActiveRecord::Migration[8.0]
  def change
    create_table :quotation_items do |t|
      t.references :quotation, null: false, foreign_key: true
      t.string :product_code, null: false
      t.string :product_name, null: false
      t.integer :unit_price, null: false, default: 0
      t.integer :quantity, null: false, default: 1
      t.integer :amount, null: false, default: 0

      t.timestamps
    end
    
    add_index :quotation_items, :product_code
  end
end
