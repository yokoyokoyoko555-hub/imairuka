class CreateReceiptHistories < ActiveRecord::Migration[8.0]
  def change
    create_table :receipt_histories do |t|
      t.references :receipt, null: false, foreign_key: true
      t.string :action, null: false
      t.string :user, null: false
      t.text :details
      t.datetime :discarded_at

      t.timestamps
    end
    add_index :receipt_histories, :discarded_at
  end
end
