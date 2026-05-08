class UpdatePaymentPendingToWaitingPayment < ActiveRecord::Migration[8.0]
  def up
    # 見積書のpayment_pendingをwaiting_paymentに変換
    execute <<-SQL
      UPDATE quotations 
      SET status = 'waiting_payment' 
      WHERE status = 'payment_pending'
    SQL
    
    # 請求書のpayment_pendingをwaiting_paymentに変換
    execute <<-SQL
      UPDATE invoices 
      SET status = 'waiting_payment' 
      WHERE status = 'payment_pending'
    SQL
  end

  def down
    # 見積書のwaiting_paymentをpayment_pendingに戻す
    execute <<-SQL
      UPDATE quotations 
      SET status = 'payment_pending' 
      WHERE status = 'waiting_payment'
    SQL
    
    # 請求書のwaiting_paymentをpayment_pendingに戻す
    execute <<-SQL
      UPDATE invoices 
      SET status = 'payment_pending' 
      WHERE status = 'waiting_payment'
    SQL
  end
end
