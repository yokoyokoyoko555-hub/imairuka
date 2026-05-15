class AddAccountBillingFieldsToCompanies < ActiveRecord::Migration[8.0]
  def change
    add_column :companies, :additional_user_slots, :integer, null: false, default: 0
    add_column :companies, :stripe_additional_users_subscription_id, :string
    add_column :companies, :stripe_additional_users_subscription_status, :string

    add_index :companies, :stripe_additional_users_subscription_id
  end
end
