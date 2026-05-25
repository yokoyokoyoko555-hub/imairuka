class AddLoginOtpToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :login_otp_digest, :string
    add_column :users, :login_otp_sent_at, :datetime
    add_column :users, :login_otp_expires_at, :datetime
    add_column :users, :login_otp_attempts, :integer, null: false, default: 0

    add_index :users, :login_otp_expires_at
  end
end
