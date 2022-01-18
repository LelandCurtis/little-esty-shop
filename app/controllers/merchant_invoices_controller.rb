class MerchantInvoicesController < ApplicationController
  def index
    @merchant = Merchant.find(params[:id])
    @invoices = Item.invoice_finder(params[:id])
  end

  def show
    @merchant = Merchant.find(params[:merchant_id])
    @invoice = Invoice.find(params[:invoice_id])
    @discounted_revenue = InvoiceItem.discounted_revenue_by_merchant_invoice(@merchant, @invoice)
  end
end
