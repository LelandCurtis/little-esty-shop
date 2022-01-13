class MerchantDiscountsController < ApplicationController
  def index
    @merchant = Merchant.find(params[:merchant_id])
    @discounts = Discount.all
  end

  def show
    @merchant = Merchant.find(params[:merchant_id])
    @discount = Discount.find(params[:id])
  end

  def new
    @merchant = Merchant.find(params[:merchant_id])
    @discount = Discount.create()
  end

  def create
    merchant = Merchant.find(params[:merchant_id])
    discount = merchant.discounts.create(discount_params)
    redirect_to "/merchants/#{merchant.id}/discounts"
  end

  def destroy
    merchant = Merchant.find(params[:merchant_id])
    discount = Discount.find(params[:id])
    discount.destroy
    redirect_to "/merchants/#{merchant.id}/discounts"
  end

  private

  def discount_params
    params.require(:discount).permit(:name, :discount_rate, :threshold_quantity)
  end
end