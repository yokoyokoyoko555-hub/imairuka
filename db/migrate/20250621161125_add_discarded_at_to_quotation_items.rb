class AddDiscardedAtToQuotationItems < ActiveRecord::Migration[8.0]
  def change
    add_column :quotation_items, :discarded_at, :datetime
    add_index :quotation_items, :discarded_at
  end
end
