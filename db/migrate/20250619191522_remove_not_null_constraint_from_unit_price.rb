class RemoveNotNullConstraintFromUnitPrice < ActiveRecord::Migration[8.0]
  def change
    change_column_null :products, :unit_price, true
  end
end
