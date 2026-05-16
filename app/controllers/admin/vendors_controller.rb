module Admin
  class VendorsController < ApplicationController
    layout "admin"

    before_action -> { require_role!(:platform_admin) }
    before_action :set_vendor, only: [:show, :edit, :update]

    def index
      @vendors = Vendor.recent.includes(:companies)
    end

    def show
      @companies = @vendor.companies.order(created_at: :desc)
    end

    def new
      @vendor = Vendor.new(status: "active")
    end

    def create
      @vendor = Vendor.new(vendor_params)

      if @vendor.save
        redirect_to admin_vendor_path(@vendor), notice: "ベンダーを追加しました。"
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @vendor.update(vendor_params)
        redirect_to admin_vendor_path(@vendor), notice: "ベンダー情報を更新しました。"
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def set_vendor
      @vendor = Vendor.find(params[:id])
    end

    def vendor_params
      params.require(:vendor).permit(
        :code,
        :name,
        :contact_name,
        :email,
        :phone,
        :postal_code,
        :address,
        :status,
        :notes
      )
    end
  end
end
