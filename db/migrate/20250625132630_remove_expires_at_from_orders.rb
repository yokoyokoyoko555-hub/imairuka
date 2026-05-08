class RemoveExpiresAtFromOrders < ActiveRecord::Migration[8.0]
  def up
    if column_exists?(:orders, :expires_at)
      remove_column :orders, :expires_at, :datetime
      remove_index :orders, :expires_at if index_exists?(:orders, :expires_at)
    end
  end

  def down
    unless column_exists?(:orders, :expires_at)
      add_column :orders, :expires_at, :datetime
      add_index :orders, :expires_at
    end
  end
end
