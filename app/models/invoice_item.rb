class InvoiceItem < ApplicationRecord
  belongs_to :item
  has_many :merchants, through: :item
  has_many :discounts, through: :merchants
  belongs_to :invoice
  has_many :transactions, through: :invoice

  validates :quantity, presence: true, numericality: {only_integer: true}
  validates :unit_price, presence: true, numericality: {only_integer: true}

  enum status: { "pending" => 0, :packaged => 1, "shipped" =>2 }

  scope :total_revenue, ->{sum('invoice_items.quantity * invoice_items.unit_price')}

  scope :grouped_total_revenue, -> {select('SUM (invoice_items.quantity * invoice_items.unit_price) AS revenue').group(:id)}

  def self.revenue
    joins(invoice: :transactions)
    .merge(Transaction.successful)
    .total_revenue
  end

  def self.revenue_discount
    json = select('SUM(best_rev.best_revenue_discount) AS totaled_revenue_discount')
    .from(self.group('inner_query.item_id')
      .select('MAX(inner_query.total_revenue_discount) AS best_revenue_discount')
      .from(self.joins(:transactions, :discounts).merge(Transaction.successful)
        .group("invoice_items.item_id", "discounts.id")
        .select('invoice_items.item_id', 'discounts.id', 'discounts.quantity',
          'SUM(((discounts.discount) * invoice_items.unit_price * invoice_items.quantity) / 100) AS total_revenue_discount',
          'SUM(invoice_items.quantity) AS total_item_quantity')
        .having('discounts.quantity <= SUM(invoice_items.quantity)'), :inner_query), :best_rev).to_json

    hash = JSON.parse(json)[0]
    discount = hash['totaled_revenue_discount'].to_i
  end

  def self.revenue_discount_by_merchant_invoice(merchant, invoice)

    json = select('SUM(best_rev.best_revenue_discount) AS totaled_revenue_discount')
    .from(self.group('inner_query.item_id')
      .select('MAX(inner_query.total_revenue_discount) AS best_revenue_discount')
      .from(self.joins(:transactions, :discounts).merge(Transaction.successful)
        .where(merchants: {id: merchant.id}, invoice_id: invoice.id)
        .group("invoice_items.item_id", "discounts.id", 'invoice_items.invoice_id', 'merchants.id')
        .select('invoice_items.item_id', 'discounts.id', 'discounts.quantity', 'invoice_items.invoice_id', 'merchants.id',
          'SUM(((discounts.discount) * invoice_items.unit_price * invoice_items.quantity) / 100) AS total_revenue_discount',
          'SUM(invoice_items.quantity) AS total_item_quantity')
        .having('discounts.quantity <= SUM(invoice_items.quantity)'), :inner_query), :best_rev).to_json

    hash = JSON.parse(json)[0]
    discount = hash['totaled_revenue_discount'].to_i
  end

  def self.revenue_discount_by_invoice(invoice)

    json = select('SUM(best_rev.best_revenue_discount) AS totaled_revenue_discount')
    .from(self.group('inner_query.item_id')
      .select('MAX(inner_query.total_revenue_discount) AS best_revenue_discount')
      .from(self.joins(:transactions, :discounts).merge(Transaction.successful)
        .where(invoice_id: invoice.id)
        .group("invoice_items.item_id", "discounts.id", 'invoice_items.invoice_id', 'merchants.id')
        .select('invoice_items.item_id', 'discounts.id', 'discounts.quantity', 'invoice_items.invoice_id', 'merchants.id',
          'SUM(((discounts.discount) * invoice_items.unit_price * invoice_items.quantity) / 100) AS total_revenue_discount',
          'SUM(invoice_items.quantity) AS total_item_quantity')
        .having('discounts.quantity <= SUM(invoice_items.quantity)'), :inner_query), :best_rev).to_json

    hash = JSON.parse(json)[0]
    discount = hash['totaled_revenue_discount'].to_i
  end

  def self.discounted_revenue
    self.revenue - self.revenue_discount
  end

  def self.discounted_revenue_by_merchant_invoice(merchant, invoice)
    invoice.revenue_by_merchant(merchant) - self.revenue_discount_by_merchant_invoice(merchant, invoice)
  end

  def self.discounted_revenue_by_invoice(invoice)
    invoice.revenue - self.revenue_discount_by_invoice(invoice)
  end

  def item_name
    item.name
  end

  def item_id
    item.id
  end

  def item_best_discount
    item.best_discount
  end

  def item_best_discount_id
    item_best_discount.id
  end
end
