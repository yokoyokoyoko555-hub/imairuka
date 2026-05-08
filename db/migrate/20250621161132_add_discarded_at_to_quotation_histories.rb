class AddDiscardedAtToQuotationHistories < ActiveRecord::Migration[8.0]
  def change
    add_column :quotation_histories, :discarded_at, :datetime
    add_index :quotation_histories, :discarded_at
  end
end
