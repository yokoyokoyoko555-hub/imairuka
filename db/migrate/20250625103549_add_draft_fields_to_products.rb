class AddDraftFieldsToProducts < ActiveRecord::Migration[8.0]
  def change
    add_column :products, :draft, :boolean
    add_column :products, :session_id, :string
    add_column :products, :expires_at, :datetime
  end
end
