class RenameUserToStaffNameInOrderHistories < ActiveRecord::Migration[7.1]
  def change
    rename_column :order_histories, :user, :staff_name
  end
end
