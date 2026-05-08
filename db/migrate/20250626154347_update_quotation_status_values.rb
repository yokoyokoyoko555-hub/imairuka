class UpdateQuotationStatusValues < ActiveRecord::Migration[8.0]
  def up
    Quotation.where(status: 'preparation').update_all(status: '送付待ち')
    Quotation.where(status: 'approved').update_all(status: '入金待ち')
    Quotation.where(status: 'expired').update_all(status: '入金済み')
  end

  def down
    Quotation.where(status: '送付待ち').update_all(status: 'preparation')
    Quotation.where(status: '入金待ち').update_all(status: 'approved')
    Quotation.where(status: '入金済み').update_all(status: 'expired')
  end
end
