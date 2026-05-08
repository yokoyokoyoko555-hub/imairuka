class SessionsController < ApplicationController
  skip_before_action :require_login, only: [:new, :create, :destroy]
  # モックアップ用に認証を無効化
  # skip_before_action :require_login, only: [:new, :create]
  layout 'auth'  # ログイン画面用のレイアウトを指定

  def new
    if current_user
      redirect_to root_path
      return
    end
    # ログイン画面の表示
  end

  def create
    if current_user
      redirect_to root_path
      return
    end
    user = User.find_by(email: params[:email])
    if user&.authenticate(params[:password])
      session[:user_id] = user.id
      if params[:remember_me] == '1'
        user.remember
        cookies.permanent.signed[:user_id] = {
          value: user.id,
          secure: Rails.env.production?,
          same_site: :lax
        }
        cookies.permanent[:remember_token] = {
          value: user.remember_token,
          secure: Rails.env.production?,
          same_site: :lax
        }
      else
        user.forget
        cookies.delete(:user_id)
        cookies.delete(:remember_token)
      end
      redirect_to root_path, notice: "ログインしました"
    else
      flash.now[:alert] = "メールアドレスまたはパスワードが正しくありません"
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    if current_user
      current_user.forget
    end
    session[:user_id] = nil
    cookies.delete(:user_id)
    cookies.delete(:remember_token)
    redirect_to login_path, notice: "ログアウトしました"
  end
end 