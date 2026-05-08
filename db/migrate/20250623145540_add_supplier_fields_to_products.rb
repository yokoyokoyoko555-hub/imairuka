class AddSupplierFieldsToProducts < ActiveRecord::Migration[8.0]
  def change
    add_column :products, :supplier_name, :string
    add_column :products, :supplier_contact, :string
    add_column :products, :supplier_phone, :string
    add_column :products, :supplier_email, :string
  end
end
