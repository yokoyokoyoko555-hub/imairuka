class AddStripeConnectFieldsToCompanies < ActiveRecord::Migration[8.0]
  def change
    add_column :companies, :stripe_account_id, :string
    add_column :companies, :stripe_charges_enabled, :boolean, default: false, null: false
    add_column :companies, :stripe_payouts_enabled, :boolean, default: false, null: false
    add_column :companies, :stripe_details_submitted, :boolean, default: false, null: false
    add_column :companies, :stripe_onboarded_at, :datetime

    add_index :companies, :stripe_account_id, unique: true
  end
end
