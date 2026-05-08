class UpdateDeliveryNoteStatusValues < ActiveRecord::Migration[8.0]
  def up
    DeliveryNote.where(status: 'preparation').update_all(status: 'pending')
    DeliveryNote.where(status: 'approved').update_all(status: 'payment_pending')
    DeliveryNote.where(status: 'expired').update_all(status: 'paid')
  end

  def down
    DeliveryNote.where(status: 'pending').update_all(status: 'preparation')
    DeliveryNote.where(status: 'payment_pending').update_all(status: 'approved')
    DeliveryNote.where(status: 'paid').update_all(status: 'expired')
  end
end
