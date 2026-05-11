class CreateUserInvitations < ActiveRecord::Migration[8.0]
  def change
    create_table :user_invitations do |t|
      t.references :company, null: false, foreign_key: true
      t.references :invited_by, foreign_key: { to_table: :users }
      t.string :email, null: false
      t.string :name
      t.string :role, null: false, default: "member"
      t.string :token_digest, null: false
      t.datetime :accepted_at
      t.datetime :expires_at, null: false

      t.timestamps
    end

    add_index :user_invitations, :token_digest, unique: true
    add_index :user_invitations, [:company_id, :email]
    add_index :user_invitations, :accepted_at
  end
end
