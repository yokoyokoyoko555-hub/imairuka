class UpdateCustomersCodeIndex < ActiveRecord::Migration[8.0]
  def change
    # 既存の一意制約を削除
    remove_index :customers, :code, name: "index_customers_on_code"
    
    # 新しい複合一意制約を追加（商品管理と同じ形式）
    add_index :customers, [:code, :discarded_at], unique: true, name: "index_customers_on_code_and_discarded_at"
  end
end
