class CreateReceipts < ActiveRecord::Migration[8.0]
  def change
    create_table :receipts do |t|
      t.string :receipt_number, null: false
      t.date :issue_date, null: false
      t.string :customer_name, null: false
      t.string :customer_address
      t.string :subject
      t.string :staff_name, null: false
      t.string :payment_method
      t.date :payment_date
      t.string :status, default: 'draft'
      t.text :notes
      t.integer :total_amount, default: 0
      t.datetime :discarded_at

      t.timestamps
    end
    
    add_index :receipts, :receipt_number, unique: true
    add_index :receipts, :discarded_at
  end
end
