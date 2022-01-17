class MerchantDiscountsController < ApplicationController

  def index
    @merchant = Merchant.find(params[:merchant_id])
    @discounts = @merchant.discounts
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
    if discount.id
      flash[:notice] = "New Discount Created"
      redirect_to "/merchants/#{params[:merchant_id]}/discounts"
    else
      flash[:alert] = "Error: #{discount.errors.full_messages.to_sentence}"
      redirect_to "/merchants/#{params[:merchant_id]}/discounts/new"
    end
  end


  private

  def discount_params
    params.require(:discount).permit(:quantity, :discount, :merchant_id)
  end
end
