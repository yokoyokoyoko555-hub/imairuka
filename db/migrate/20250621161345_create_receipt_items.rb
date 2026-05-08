class CreateReceiptItems < ActiveRecord::Migration[8.0]
  def change
    create_table :receipt_items do |t|
      t.references :receipt, null: false, foreign_key: true
      t.string :product_code, null: false
      t.string :product_name, null: false
      t.integer :unit_price, null: false, default: 0
      t.integer :quantity, null: false, default: 1
      t.integer :amount, null: false, default: 0
      t.integer :tax_rate
      t.datetime :discarded_at

      t.timestamps
    end
    add_index :receipt_items, :discarded_at
  end
end
