class CreateInvoices < ActiveRecord::Migration[8.0]
  def change
    create_table :invoices do |t|
      t.string :invoice_number, null: false
      t.date :invoice_date, null: false
      t.string :customer_name, null: false
      t.text :customer_address
      t.string :subject
      t.string :staff_name, null: false
      t.string :status, null: false, default: 'draft'
      t.text :notes
      t.integer :total_amount, null: false, default: 0
      t.date :payment_due_date
      t.datetime :discarded_at

      t.timestamps
    end
    
    add_index :invoices, :invoice_number, unique: true
    add_index :invoices, :invoice_date
    add_index :invoices, :customer_name
    add_index :invoices, :status
    add_index :invoices, :discarded_at
  end
end
