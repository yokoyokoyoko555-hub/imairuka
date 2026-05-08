class AddBillingDateToOrders < ActiveRecord::Migration[8.0]
  def change
    add_column :orders, :billing_date, :date
  end
end
