class CreateOrderHistories < ActiveRecord::Migration[7.1]
  def change
    create_table :order_histories do |t|
      t.references :order, null: false, foreign_key: true
      t.string :action, null: false
      t.text :description, null: false

      t.timestamps
    end

    add_index :order_histories, :action
    add_index :order_histories, :created_at
  end
end
