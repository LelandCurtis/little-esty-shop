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

  def edit
    @merchant = Merchant.find(params[:merchant_id])
    @discount = Discount.find(params[:id])
  end

  def update
    merchant = Merchant.find(params[:merchant_id])
    discount = Discount.find(params[:id])

    if discount.update(discount_params)
      flash[:notice] = "Discount #{discount.id} Successfully Updated"
      redirect_to "/merchants/#{params[:merchant_id]}/discounts/#{params[:id]}"
    else
      flash[:alert] = "Error: #{discount.errors.full_messages.to_sentence}"
      redirect_to "/merchants/#{params[:merchant_id]}/discounts/#{params[:id]}/edit"
    end
  end

  def destroy
    merchant = Merchant.find(params[:merchant_id])
    discount = Discount.find(params[:id])
    if discount.delete
      flash[:notice] = "Discount Deleted"
      redirect_to "/merchants/#{params[:merchant_id]}/discounts"
    else
      flash[:alert] = "Error: #{discount.errors.full_messages.to_sentence}"
      redirect_to "/merchants/#{params[:merchant_id]}/discounts"
    end
  end


  private

  def discount_params
    params.require(:discount).permit(:quantity, :discount, :merchant_id)
  end
end
