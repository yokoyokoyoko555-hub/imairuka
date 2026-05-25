class UserMailer < ApplicationMailer
  def self.otp_delivery_available?
    !Rails.env.production? || ENV["SMTP_ADDRESS"].present?
  end

  def login_otp(user, otp_code)
    @user = user
    @otp_code = otp_code

    mail(to: user.email, subject: "Imairuka ログイン認証コード")
  end
end
