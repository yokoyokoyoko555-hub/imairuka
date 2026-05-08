class AddDraftFieldsToQuotations < ActiveRecord::Migration[8.0]
  def change
    add_column :quotations, :draft, :boolean, default: false, null: false
    add_column :quotations, :session_id, :string
    add_column :quotations, :expires_at, :datetime
    
    add_index :quotations, :draft
    add_index :quotations, :session_id
    add_index :quotations, :expires_at
    
    # 一時保存データの場合は必須項目をNULL許可にする
    change_column_null :quotations, :quotation_number, true
    change_column_null :quotations, :customer_name, true
    change_column_null :quotations, :staff_name, true
  end
end
