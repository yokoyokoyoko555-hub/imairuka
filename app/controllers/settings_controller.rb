class SettingsController < ApplicationController
  def index
    # 会社情報の取得
    @company = Company.first_or_initialize

    # ステータス情報の取得
    if params[:tab] == 'status'
      @order_statuses = OrderStatus.active.ordered
    end
  end

  def update
    @company = Company.first_or_initialize

    if @company.new_record?
      @company.assign_attributes(company_params)

      if @company.save
        flash[:success] = "会社情報を登録しました"
        redirect_to settings_path(tab: params[:tab])
      else
        @order_statuses = OrderStatus.active.ordered if params[:tab] == 'status'
        render :index, status: :unprocessable_entity
      end
    else
      if @company.update(company_params)
        flash[:success] = "会社情報を更新しました"
        redirect_to settings_path(tab: params[:tab])
      else
        @order_statuses = OrderStatus.active.ordered if params[:tab] == 'status'
        render :index, status: :unprocessable_entity
      end
    end
  end

  private

  def company_params
    params.require(:company).permit(:name, :invoice_number, :postal_code, :address, :phone, :email, :representative, :business_type)
  end
end 