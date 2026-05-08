class UpdateCustomerCodeUniqueIndex < ActiveRecord::Migration[8.0]
  def change
    # 既存のユニーク制約を削除
    remove_index :customers, :code, if_exists: true
    
    # 論理削除されていないレコードのみでユニーク制約を追加
    add_index :customers, :code, unique: true, where: "discarded_at IS NULL"
  end
end
