class AddUserToOrderHistories < ActiveRecord::Migration[7.1]
  def change
    add_column :order_histories, :user, :string, null: false, default: 'システム'
  end
end
