class AddDraftFieldsToOrders < ActiveRecord::Migration[8.0]
  def change
    add_column :orders, :draft, :boolean, default: false, null: false
    add_column :orders, :session_id, :string
    add_column :orders, :expires_at, :datetime
    
    add_index :orders, :draft
    add_index :orders, :session_id
    add_index :orders, :expires_at
    
    # 一時保存データの場合は必須項目をNULL許可にする
    change_column_null :orders, :customer_id, true
    change_column_null :orders, :staff_name, true
    change_column_null :orders, :order_status_id, true
    change_column_null :orders, :order_number, true
  end
end
