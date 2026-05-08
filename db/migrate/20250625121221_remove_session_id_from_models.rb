class RemoveSessionIdFromModels < ActiveRecord::Migration[8.0]
  def change
    remove_column :orders, :session_id, :string
    remove_column :products, :session_id, :string
    remove_column :customers, :session_id, :string
    remove_column :quotations, :session_id, :string
  end
end
