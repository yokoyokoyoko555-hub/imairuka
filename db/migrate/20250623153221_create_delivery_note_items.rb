class CreateDeliveryNoteItems < ActiveRecord::Migration[8.0]
  def change
    create_table :delivery_note_items do |t|
      t.references :delivery_note, null: false, foreign_key: true
      t.string :product_code
      t.string :product_name
      t.integer :unit_price
      t.integer :quantity
      t.integer :amount
      t.integer :tax_rate
      t.datetime :discarded_at

      t.timestamps
    end
    add_index :delivery_note_items, :discarded_at
  end
end
