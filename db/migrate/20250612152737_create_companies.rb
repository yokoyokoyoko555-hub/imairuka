class CreateCompanies < ActiveRecord::Migration[8.0]
  def change
    create_table :companies do |t|
      t.string :name
      t.string :invoice_number
      t.text :address
      t.string :phone
      t.string :email
      t.string :bank_name
      t.string :bank_branch
      t.string :bank_account_type
      t.string :bank_account_number
      t.string :bank_account_name

      t.timestamps
    end
  end
end
