class Item < ApplicationRecord
  belongs_to :merchant
  has_many :discounts, through: :merchant
  has_many :invoice_items
  has_many :invoices, through: :invoice_items
  has_many :transactions, through: :invoices

  enum status: [:Disabled, :Enabled]

  validates :name, presence: true
  validates :description, presence: true
  validates :unit_price, presence: true, numericality: {only_integer: true}


  def self.invoice_finder(merchant_id)
    Invoice.joins(:invoice_items => :item).where(:items => {:merchant_id => merchant_id}).distinct
  end

  def self.enabled_items
    Item.all.where(status: 1)
  end

  def self.disabled_items
    Item.all.where(status: 0)
  end

  def revenue
    invoice_items.revenue
  end

  def best_day
    invoices.joins(:transactions, :invoice_items)
    .select("invoices.*")
    .merge(Transaction.successful)
    .merge(InvoiceItem.grouped_total_revenue)
    .order(:revenue)
    .first.created_at
  end

  def best_discount
    json = invoice_items.joins(:discounts)
    .group("invoice_items.item_id", "discounts.id")
    .select('invoice_items.item_id', 'discounts.id AS discounts_ID', 'discounts.quantity',
      'SUM(((discounts.discount) * invoice_items.unit_price * invoice_items.quantity) / 100) AS total_revenue_discount',
      'SUM(invoice_items.quantity) AS total_item_quantity')
    .having('discounts.quantity <= SUM(invoice_items.quantity)')
    .order(total_revenue_discount: :desc)
    .first.to_json

    hash = JSON.parse(json)
    if hash
      return Discount.find(hash['discounts_id'])
    else
      return nil
    end
  end

  def best_discount_id
    discount = best_discount
    if discount
      return "#{discount.id}"
    else
      return "None"
    end
  end

end
