class AddDraftFieldsToCustomers < ActiveRecord::Migration[8.0]
  def change
    add_column :customers, :draft, :boolean, default: false, null: false
    add_column :customers, :session_id, :string
    add_column :customers, :expires_at, :datetime
    
    add_index :customers, :draft
    add_index :customers, :session_id
    add_index :customers, :expires_at
    
    # 一時保存データの場合は必須項目をNULL許可にする
    change_column_null :customers, :name, true
    change_column_null :customers, :email, true
    change_column_null :customers, :phone, true
  end
end
