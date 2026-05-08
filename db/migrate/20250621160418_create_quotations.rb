class CreateQuotations < ActiveRecord::Migration[8.0]
  def change
    create_table :quotations do |t|
      t.string :quotation_number, null: false
      t.date :quotation_date, null: false
      t.string :customer_name, null: false
      t.integer :total_amount, null: false, default: 0
      t.string :status, null: false, default: 'draft'
      t.string :staff_name, null: false
      t.date :valid_until
      t.text :notes

      t.timestamps
    end
    
    add_index :quotations, :quotation_number, unique: true
    add_index :quotations, :quotation_date
    add_index :quotations, :customer_name
    add_index :quotations, :status
  end
end
