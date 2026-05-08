class AddDiscardedAtToQuotations < ActiveRecord::Migration[8.0]
  def change
    add_column :quotations, :discarded_at, :datetime
    add_index :quotations, :discarded_at
  end
end
