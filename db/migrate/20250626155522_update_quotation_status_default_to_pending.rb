class UpdateQuotationStatusDefaultToPending < ActiveRecord::Migration[8.0]
  def up
    change_column_default :quotations, :status, 'pending'
  end

  def down
    change_column_default :quotations, :status, 'preparation'
  end
end
