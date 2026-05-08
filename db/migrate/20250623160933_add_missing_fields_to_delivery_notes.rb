class AddMissingFieldsToDeliveryNotes < ActiveRecord::Migration[8.0]
  def change
    add_column :delivery_notes, :customer_address, :text
    add_column :delivery_notes, :subject, :string
  end
end
