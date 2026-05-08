class CreateInvoiceHistories < ActiveRecord::Migration[8.0]
  def change
    create_table :invoice_histories do |t|
      t.references :invoice, null: false, foreign_key: true
      t.string :action, null: false
      t.string :user, null: false

      t.timestamps
    end
    
    add_index :invoice_histories, :action
    add_index :invoice_histories, :created_at
  end
end
