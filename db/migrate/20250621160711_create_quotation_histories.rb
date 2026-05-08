class CreateQuotationHistories < ActiveRecord::Migration[8.0]
  def change
    create_table :quotation_histories do |t|
      t.references :quotation, null: false, foreign_key: true
      t.string :action, null: false
      t.string :user, null: false

      t.timestamps
    end
    
    add_index :quotation_histories, :created_at
  end
end
