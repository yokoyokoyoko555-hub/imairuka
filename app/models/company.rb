class Company < ApplicationRecord
  validates :name, presence: true, length: { maximum: 100, message: '会社名は100文字以内で入力してください' }
  validates :invoice_number, presence: true, format: { with: /\AT\d{13}\z/, message: "は13桁の数字で、先頭にTを付けてください" }, length: { maximum: 20, message: 'インボイス登録番号は20文字以内で入力してください' }
  validates :postal_code, presence: true, format: { with: /\A\d{7}\z/, message: "は7桁の数字で入力してください" }, length: { maximum: 10, message: '郵便番号は10文字以内で入力してください' }
  validates :address, presence: true, length: { maximum: 500, message: '住所は500文字以内で入力してください' }
  validates :phone, presence: true, format: { with: /\A\d{10,11}\z/, message: "は10桁または11桁の数字で入力してください" }, length: { maximum: 15, message: '電話番号は15文字以内で入力してください' }
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP, message: "は正しい形式で入力してください" }, length: { maximum: 100, message: 'メールアドレスは100文字以内で入力してください' }
  validates :representative, presence: true, length: { maximum: 50, message: '代表者名は50文字以内で入力してください' }
  validates :business_type, presence: true, length: { maximum: 50, message: '業種は50文字以内で入力してください' }

  before_validation :normalize_postal_code, :normalize_phone

  def stripe_connected?
    stripe_account_id.present? && stripe_charges_enabled?
  end

  def stripe_connect_status
    return "未連携" if stripe_account_id.blank?
    return "利用可能" if stripe_charges_enabled?
    return "審査中" if stripe_details_submitted?

    "設定未完了"
  end

  private

  def normalize_postal_code
    if postal_code.present?
      # 数字とハイフン以外が含まれているかチェック
      if postal_code.match?(/[^\d-]/)
        errors.add(:postal_code, "には数字とハイフンのみ入力してください")
        return
      end
      # ハイフンを削除して数字のみにする
      self.postal_code = postal_code.gsub(/[^\d]/, '')
    end
  end

  def normalize_phone
    if phone.present?
      # 数字とハイフン以外が含まれているかチェック
      if phone.match?(/[^\d-]/)
        errors.add(:phone, "には数字とハイフンのみ入力してください")
        return
      end
      # ハイフンを削除して数字のみにする
      self.phone = phone.gsub(/[^\d]/, '')
    end
  end
end
