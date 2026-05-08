class RemoveDeliveryStaffFromOrders < ActiveRecord::Migration[8.0]
  def change
    remove_column :orders, :delivery_staff, :string
  end
end
