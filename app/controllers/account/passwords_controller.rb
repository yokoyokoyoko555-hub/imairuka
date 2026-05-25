module Account
  class PasswordsController < ApplicationController
    def edit
    end

    def update
      unless current_user.authenticate(password_params[:current_password])
        redirect_to edit_account_password_path, alert: "現在のパスワードが正しくありません。"
        return
      end

      if current_user.update(password: password_params[:password], password_confirmation: password_params[:password_confirmation])
        redirect_to settings_path, notice: "パスワードを変更しました。"
      else
        flash.now[:alert] = current_user.errors.full_messages.join("、")
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def password_params
      params.require(:user).permit(:current_password, :password, :password_confirmation)
    end
  end
end
