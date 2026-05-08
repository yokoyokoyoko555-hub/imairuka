class UpdateReceiptStatusDefaultToPending < ActiveRecord::Migration[8.0]
  def up
    # 既存のenum値を新しい値に変換
    execute <<-SQL
      UPDATE receipts 
      SET status = CASE 
        WHEN status = 'draft' THEN 'pending'
        WHEN status = 'sent' THEN 'sent'
        WHEN status = 'paid' THEN 'paid'
        ELSE 'pending'
      END
    SQL
    
    # デフォルト値を'pending'に変更
    change_column_default :receipts, :status, 'pending'
  end

  def down
    # 元のenum値に戻す
    execute <<-SQL
      UPDATE receipts 
      SET status = CASE 
        WHEN status = 'pending' THEN 'draft'
        WHEN status = 'sent' THEN 'sent'
        WHEN status = 'paid' THEN 'paid'
        ELSE 'draft'
      END
    SQL
    
    # デフォルト値を'draft'に戻す
    change_column_default :receipts, :status, 'draft'
  end
end
