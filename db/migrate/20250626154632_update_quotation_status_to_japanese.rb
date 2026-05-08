class UpdateQuotationStatusToJapanese < ActiveRecord::Migration[8.0]
  def up
    Quotation.where(status: 'preparation').update_all(status: 'pending')
    Quotation.where(status: 'approved').update_all(status: 'payment_pending')
    Quotation.where(status: 'expired').update_all(status: 'paid')
  end

  def down
    Quotation.where(status: 'pending').update_all(status: 'preparation')
    Quotation.where(status: 'payment_pending').update_all(status: 'approved')
    Quotation.where(status: 'paid').update_all(status: 'expired')
  end
end
