class AddFieldsToCompanies < ActiveRecord::Migration[8.0]
  def change
    add_column :companies, :postal_code, :string, comment: '郵便番号'
    add_column :companies, :representative, :string, comment: '代表者名'
    add_column :companies, :business_type, :string, comment: '業種'
  end
end
