class FixQuotationNumberUniqueConstraint < ActiveRecord::Migration[7.1]
  def change
    # 既存のユニーク制約を削除
    remove_index :quotations, :quotation_number, if_exists: true
    
    # 論理削除に対応したユニーク制約を追加（discarded_atがNULLの場合のみユニーク）
    add_index :quotations, :quotation_number, unique: true, where: "discarded_at IS NULL"
  end
end
