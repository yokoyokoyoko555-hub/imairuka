class FixUniqueConstraintsForDocuments < ActiveRecord::Migration[7.0]
  def up
    # 請求書のユニーク制約を修正（見積書と同じ仕様）
    remove_index :invoices, :invoice_number
    add_index :invoices, :invoice_number, unique: true, where: "discarded_at IS NULL"
    
    # 納品書にユニーク制約を追加（見積書と同じ仕様）
    add_index :delivery_notes, :delivery_number, unique: true, where: "discarded_at IS NULL"
    
    # 領収書にユニーク制約を追加（見積書と同じ仕様）
    add_index :receipts, :receipt_number, unique: true, where: "discarded_at IS NULL"
  end

  def down
    # 請求書を元に戻す
    remove_index :invoices, :invoice_number
    add_index :invoices, :invoice_number, unique: true
    
    # 納品書のユニーク制約を削除
    remove_index :delivery_notes, :delivery_number
    
    # 領収書のユニーク制約を削除
    remove_index :receipts, :receipt_number
  end
end
