class UpdateDeliveryNotePaymentPendingToWaitingPayment < ActiveRecord::Migration[8.0]
  def up
    # 納品書のpayment_pendingをwaiting_paymentに変換
    execute <<-SQL
      UPDATE delivery_notes 
      SET status = 'waiting_payment' 
      WHERE status = 'payment_pending'
    SQL
  end

  def down
    # 納品書のwaiting_paymentをpayment_pendingに戻す
    execute <<-SQL
      UPDATE delivery_notes 
      SET status = 'payment_pending' 
      WHERE status = 'waiting_payment'
    SQL
  end
end
