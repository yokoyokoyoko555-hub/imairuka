class AddAddressToQuotations < ActiveRecord::Migration[8.0]
  def change
    add_column :quotations, :customer_address, :text
  end
end
