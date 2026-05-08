class CreateDeliveryNoteHistories < ActiveRecord::Migration[8.0]
  def change
    create_table :delivery_note_histories do |t|
      t.references :delivery_note, null: false, foreign_key: true
      t.string :action
      t.string :user
      t.datetime :discarded_at

      t.timestamps
    end
  end
end
