class AddTransactionDateToInvoicesAndDeliveryNotes < ActiveRecord::Migration[8.0]
  def change
    add_column :invoices, :transaction_date, :date
    add_column :delivery_notes, :transaction_date, :date
  end
end
