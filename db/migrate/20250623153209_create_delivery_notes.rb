class CreateDeliveryNotes < ActiveRecord::Migration[8.0]
  def change
    create_table :delivery_notes do |t|
      t.string :delivery_number
      t.date :delivery_date
      t.string :customer_name
      t.string :staff_name
      t.string :status
      t.text :notes
      t.integer :total_amount
      t.date :valid_until
      t.datetime :discarded_at

      t.timestamps
    end
    add_index :delivery_notes, :discarded_at
  end
end
