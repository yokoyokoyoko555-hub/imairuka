class RemoveUserFromHistories < ActiveRecord::Migration[8.0]
  def change
    remove_column :quotation_histories, :user, :string
    remove_column :invoice_histories, :user, :string
    remove_column :receipt_histories, :user, :string
    remove_column :delivery_note_histories, :user, :string
  end
end 