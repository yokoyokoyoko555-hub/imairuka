class CreateOrderStatuses < ActiveRecord::Migration[7.1]
  def change
    create_table :order_statuses do |t|
      t.string :name, null: false, comment: 'ステータス名'
      t.string :code, null: false, comment: 'ステータスコード'
      t.integer :display_order, null: false, default: 1, comment: '表示順'
      t.string :color, comment: '表示色'
      t.text :description, comment: '説明'
      t.boolean :is_active, null: false, default: true, comment: '有効フラグ'
      t.timestamps
    end

    add_index :order_statuses, :code, unique: true
    add_index :order_statuses, :display_order
    add_index :order_statuses, :is_active
  end
end 