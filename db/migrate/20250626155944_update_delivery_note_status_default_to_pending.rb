class UpdateDeliveryNoteStatusDefaultToPending < ActiveRecord::Migration[8.0]
  def up
    change_column_default :delivery_notes, :status, 'pending'
  end

  def down
    change_column_default :delivery_notes, :status, 'preparation'
  end
end
