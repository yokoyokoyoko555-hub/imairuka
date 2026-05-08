class AddProductFieldsForConsistency < ActiveRecord::Migration[8.0]
  def change
    add_column :products, :cost_price, :integer
    add_column :products, :stock_quantity, :integer
    add_column :products, :stock_threshold, :integer
  end
end
