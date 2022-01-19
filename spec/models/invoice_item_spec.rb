require 'rails_helper'

RSpec.describe InvoiceItem, type: :model do

  describe 'relationships' do
    it { should belong_to(:item) }
    it { should have_many(:merchants).through(:item) }
    it { should have_many(:discounts).through(:merchants) }
    it { should belong_to(:invoice) }
    it { should have_many(:transactions).through(:invoice) }
  end

  describe 'enums validation' do
    it {should define_enum_for(:status).with([:pending, :packaged, :shipped])}
  end

  describe 'validations' do
    it { should validate_presence_of(:quantity)}
    it { should validate_numericality_of(:quantity)}
    it { should validate_presence_of(:unit_price)}
    it { should validate_numericality_of(:unit_price)}
  end

  describe 'class methods' do
    describe '.revenue' do
      it "multiplies unit_price and quantity for a collection of invoice_items and sums them only if they are associated with an invoice that has at least 1 successful transaction" do
        invoice_1 = create(:invoice)
        invoice_2 = create(:invoice)
        invoice_item_1 = create(:invoice_item, quantity: 3, unit_price: 1000, invoice: invoice_1)
        invoice_item_2 = create(:invoice_item, quantity: 5, unit_price: 1000, invoice: invoice_1)
        invoice_item_3 = create(:invoice_item, quantity: 1, unit_price: 1000, invoice: invoice_2)
        invoice_items = InvoiceItem.where(id:[invoice_item_1.id, invoice_item_2.id, invoice_item_3.id])

        # these invoice_items should not be included in any potential revenue
        invoice_3 = create(:invoice)
        invoice_item_4 = create(:invoice_item, quantity: 1, unit_price: 1000, invoice: invoice_3)
        transaction = create(:transaction, result: 0, invoice: invoice_3)

        # test for no transactions
        expect(invoice_items.revenue).to eq(0)

        # test for no successful transactions.
        transaction_1 = create(:transaction, result: 1, invoice: invoice_1)
        expect(invoice_items.revenue).to eq(0)

        # test for successful transactions
        transaction_2 = create(:transaction, result: 0, invoice: invoice_1)
        expect(invoice_items.revenue).to eq(8000)

        # test for multiple invoices with successful transactions
        transaction_3 = create(:transaction, result: 0, invoice: invoice_2)
        expect(invoice_items.revenue).to eq(9000)
      end
    end

    describe '.revenue_discount' do
      it 'reports revenue discount from all items on a given invoice if there is at least 1 successful transaction' do
        merchant = create(:merchant)
        invoice = create(:invoice)
        item_1 = create(:item, merchant: merchant)
        invoice_item_1 = create(:invoice_item, quantity: 1, unit_price: 10000, item: item_1, invoice: invoice)

        # edge case: no discounts should return 0
        transaction_2 = create(:transaction, invoice: invoice, result: 0)
        expect(InvoiceItem.revenue_discount).to eq(0)

        discount_1 = create(:discount, merchant: merchant, quantity: 3, discount: 20)
        discount_2 = create(:discount, merchant: merchant, quantity: 5, discount: 50)

        # test that it returns 0 if no discounts apply
        expect(InvoiceItem.revenue_discount).to eq(0)

        # test that it finds the best discount.
        invoice_item_2 = create(:invoice_item, quantity: 2, unit_price: 10000, item: item_1, invoice: invoice)
        expect(InvoiceItem.revenue_discount).to eq(6000)

        # test that it finds the best discount. This will increase quantity to qualify for better discount
        invoice_item_3 = create(:invoice_item, quantity: 2, unit_price: 10000, item: item_1, invoice: invoice)
        expect(InvoiceItem.revenue_discount).to eq(25000)

        #test that it finds the best discount per item and sums across multiple items.
        item_2 = create(:item, merchant: merchant)
        invoice_item_2 = create(:invoice_item, quantity: 1, unit_price: 10000, item: item_2, invoice: invoice)
        expect(InvoiceItem.revenue_discount).to eq(25000)

        invoice_item_3 = create(:invoice_item, quantity: 2, unit_price: 10000, item: item_2, invoice: invoice)
        expect(InvoiceItem.revenue_discount).to eq(31000)

        # test that it picks up the best discount for both items
        invoice_item_3 = create(:invoice_item, quantity: 3, unit_price: 10000, item: item_2, invoice: invoice)
        expect(InvoiceItem.revenue_discount).to eq(55000)
      end
    end

    describe '.revenue_discount_by_merchant_invoice(merchant, invoice)' do
      it 'reports revenue discount from all items on a given invoice if there is at least 1 successful transaction' do
        merchant = create(:merchant)
        invoice = create(:invoice)
        item_1 = create(:item, merchant: merchant)
        invoice_item_1 = create(:invoice_item, quantity: 1, unit_price: 10000, item: item_1, invoice: invoice)

        # edge case: no discounts should return 0
        transaction_2 = create(:transaction, invoice: invoice, result: 0)
        expect(InvoiceItem.revenue_discount_by_merchant_invoice(merchant, invoice)).to eq(0)

        discount_1 = create(:discount, merchant: merchant, quantity: 3, discount: 20)
        discount_2 = create(:discount, merchant: merchant, quantity: 5, discount: 50)

        # test that it returns 0 if no discounts apply
        expect(InvoiceItem.revenue_discount_by_merchant_invoice(merchant, invoice)).to eq(0)

        # test that it finds the best discount.
        invoice_item_2 = create(:invoice_item, quantity: 2, unit_price: 10000, item: item_1, invoice: invoice)
        expect(InvoiceItem.revenue_discount_by_merchant_invoice(merchant, invoice)).to eq(6000)

        # test that it finds the best discount. This will increase quantity to qualify for better discount
        invoice_item_3 = create(:invoice_item, quantity: 2, unit_price: 10000, item: item_1, invoice: invoice)
        expect(InvoiceItem.revenue_discount_by_merchant_invoice(merchant, invoice)).to eq(25000)

        #test that it finds the best discount per item and sums across multiple items.
        item_2 = create(:item, merchant: merchant)
        invoice_item_2 = create(:invoice_item, quantity: 1, unit_price: 10000, item: item_2, invoice: invoice)
        expect(InvoiceItem.revenue_discount_by_merchant_invoice(merchant, invoice)).to eq(25000)

        invoice_item_3 = create(:invoice_item, quantity: 2, unit_price: 10000, item: item_2, invoice: invoice)
        expect(InvoiceItem.revenue_discount_by_merchant_invoice(merchant, invoice)).to eq(31000)

        # test that it picks up the best discount for both items
        invoice_item_3 = create(:invoice_item, quantity: 3, unit_price: 10000, item: item_2, invoice: invoice)
        expect(InvoiceItem.revenue_discount_by_merchant_invoice(merchant, invoice)).to eq(55000)
      end
    end

    describe '.revenue_discount_by_invoice' do
      it 'reports revenue discount from all items on a given invoice regardless of merchant' do
        merchant = create(:merchant)
        invoice = create(:invoice)
        item_1 = create(:item, merchant: merchant)
        invoice_item_1 = create(:invoice_item, quantity: 1, unit_price: 10000, item: item_1, invoice: invoice)

        # edge case: no discounts should return no discount
        transaction_1 = create(:transaction, invoice: invoice, result: 0)
        expect(InvoiceItem.revenue_discount_by_invoice(invoice)).to eq(0)

        discount_1 = create(:discount, merchant: merchant, quantity: 3, discount: 20)
        discount_2 = create(:discount, merchant: merchant, quantity: 5, discount: 50)

        # test that it returns no discount if no discounts apply
        expect(InvoiceItem.revenue_discount_by_invoice(invoice)).to eq(0)

        # test that it finds the best discount.
        invoice_item_2 = create(:invoice_item, quantity: 2, unit_price: 10000, item: item_1, invoice: invoice)
        expect(InvoiceItem.revenue_discount_by_invoice(invoice)).to eq(6000)

        # test that it finds the best discount. This will increase quantity to qualify for better discount
        invoice_item_3 = create(:invoice_item, quantity: 2, unit_price: 10000, item: item_1, invoice: invoice)
        expect(InvoiceItem.revenue_discount_by_invoice(invoice)).to eq(25000)

        #test that it finds the best discount per item and sums across multiple items.
        item_2 = create(:item, merchant: merchant)
        invoice_item_4 = create(:invoice_item, quantity: 1, unit_price: 10000, item: item_2, invoice: invoice)
        invoice_item_5 = create(:invoice_item, quantity: 2, unit_price: 10000, item: item_2, invoice: invoice)
        expect(InvoiceItem.revenue_discount_by_invoice(invoice)).to eq(31000)

        # test that it picks up the best discount for both items
        invoice_item_6 = create(:invoice_item, quantity: 3, unit_price: 10000, item: item_2, invoice: invoice)
        expect(InvoiceItem.revenue_discount_by_invoice(invoice)).to eq(55000)

        #create items for another merchant and test that it picks up those properly.

        merchant_2 = create(:merchant)
        item_3 = create(:item, merchant: merchant_2)
        invoice_item_1 = create(:invoice_item, quantity: 1, unit_price: 10000, item: item_3, invoice: invoice)

        discount_3 = create(:discount, merchant: merchant_2, quantity: 4, discount: 10)
        discount_4 = create(:discount, merchant: merchant_2, quantity: 8, discount: 40)

        # test that it returns full revenue if no discounts apply
        expect(InvoiceItem.revenue_discount_by_invoice(invoice)).to eq(55000)

        # test that it finds the best discount.
        invoice_item_2 = create(:invoice_item, quantity: 3, unit_price: 10000, item: item_3, invoice: invoice)
        expect(InvoiceItem.revenue_discount_by_invoice(invoice)).to eq(59000)

        # test that it finds the best discount. This will increase quantity to qualify for better discount
        invoice_item_3 = create(:invoice_item, quantity: 5, unit_price: 10000, item: item_3, invoice: invoice)
        expect(InvoiceItem.revenue_discount_by_invoice(invoice)).to eq(91000)

        #test that it finds the best discount per item and sums across multiple items.
        item_4 = create(:item, merchant: merchant_2)
        invoice_item_2 = create(:invoice_item, quantity: 1, unit_price: 10000, item: item_4, invoice: invoice)
        invoice_item_3 = create(:invoice_item, quantity: 3, unit_price: 10000, item: item_4, invoice: invoice)
        expect(InvoiceItem.revenue_discount_by_invoice(invoice)).to eq(95000)

        # test that it picks up the best discount for both items
        invoice_item_3 = create(:invoice_item, quantity: 5, unit_price: 10000, item: item_4, invoice: invoice)
        expect(InvoiceItem.revenue_discount_by_invoice(invoice)).to eq(127000)
      end
    end

    describe '.discounted_revenue' do
      it 'reports discounted revenue from all items on a given invoice if there is at least 1 successful transaction' do
        merchant = create(:merchant)
        invoice = create(:invoice)
        item_1 = create(:item, merchant: merchant)
        invoice_item_1 = create(:invoice_item, quantity: 1, unit_price: 10000, item: item_1, invoice: invoice)

        # edge case: no discounts should return full revenue
        transaction_2 = create(:transaction, invoice: invoice, result: 0)
        expect(InvoiceItem.discounted_revenue).to eq(10000)

        discount_1 = create(:discount, merchant: merchant, quantity: 3, discount: 20)
        discount_2 = create(:discount, merchant: merchant, quantity: 5, discount: 50)

        # test that it returns full revenue if no discounts apply
        expect(InvoiceItem.discounted_revenue).to eq(10000)

        # test that it finds the best discount.
        invoice_item_2 = create(:invoice_item, quantity: 2, unit_price: 10000, item: item_1, invoice: invoice)
        expect(InvoiceItem.discounted_revenue).to eq(24000)

        # test that it finds the best discount. This will increase quantity to qualify for better discount
        invoice_item_3 = create(:invoice_item, quantity: 2, unit_price: 10000, item: item_1, invoice: invoice)
        expect(InvoiceItem.discounted_revenue).to eq(25000)

        #test that it finds the best discount per item and sums across multiple items.
        item_2 = create(:item, merchant: merchant)
        invoice_item_2 = create(:invoice_item, quantity: 1, unit_price: 10000, item: item_2, invoice: invoice)
        invoice_item_3 = create(:invoice_item, quantity: 2, unit_price: 10000, item: item_2, invoice: invoice)
        expect(InvoiceItem.discounted_revenue).to eq(49000)

        # test that it picks up the best discount for both items
        invoice_item_3 = create(:invoice_item, quantity: 3, unit_price: 10000, item: item_2, invoice: invoice)
        expect(InvoiceItem.discounted_revenue).to eq(55000)
      end
    end

    describe '.discounted_revenue_by_merchant_invoice' do
      it 'reports discounted revenue from all items on a given invoice that belongs to a specific merchant' do
        merchant = create(:merchant)
        invoice = create(:invoice)
        item_1 = create(:item, merchant: merchant)
        invoice_item_1 = create(:invoice_item, quantity: 1, unit_price: 10000, item: item_1, invoice: invoice)

        # edge case: no discounts should return full revenue
        transaction_2 = create(:transaction, invoice: invoice, result: 0)
        expect(InvoiceItem.discounted_revenue_by_merchant_invoice(merchant, invoice)).to eq(10000)

        discount_1 = create(:discount, merchant: merchant, quantity: 3, discount: 20)
        discount_2 = create(:discount, merchant: merchant, quantity: 5, discount: 50)

        # test that it returns full revenue if no discounts apply
        expect(InvoiceItem.discounted_revenue_by_merchant_invoice(merchant, invoice)).to eq(10000)

        # test that it finds the best discount.
        invoice_item_2 = create(:invoice_item, quantity: 2, unit_price: 10000, item: item_1, invoice: invoice)
        expect(InvoiceItem.discounted_revenue_by_merchant_invoice(merchant, invoice)).to eq(24000)

        # test that it finds the best discount. This will increase quantity to qualify for better discount
        invoice_item_3 = create(:invoice_item, quantity: 2, unit_price: 10000, item: item_1, invoice: invoice)
        expect(InvoiceItem.discounted_revenue_by_merchant_invoice(merchant, invoice)).to eq(25000)

        #test that it finds the best discount per item and sums across multiple items.
        item_2 = create(:item, merchant: merchant)
        invoice_item_2 = create(:invoice_item, quantity: 1, unit_price: 10000, item: item_2, invoice: invoice)
        invoice_item_3 = create(:invoice_item, quantity: 2, unit_price: 10000, item: item_2, invoice: invoice)
        expect(InvoiceItem.discounted_revenue_by_merchant_invoice(merchant, invoice)).to eq(49000)

        # test that it picks up the best discount for both items
        invoice_item_3 = create(:invoice_item, quantity: 3, unit_price: 10000, item: item_2, invoice: invoice)
        expect(InvoiceItem.discounted_revenue_by_merchant_invoice(merchant, invoice)).to eq(55000)
      end
    end

    describe '.discounted_revenue_by_invoice' do
      it 'reports discounted revenue from all items on a given invoice regardless of merchant' do
        merchant = create(:merchant)
        invoice = create(:invoice)
        item_1 = create(:item, merchant: merchant)
        invoice_item_1 = create(:invoice_item, quantity: 1, unit_price: 10000, item: item_1, invoice: invoice)

        # edge case: no discounts should return full revenue
        transaction_1 = create(:transaction, invoice: invoice, result: 0)
        expect(InvoiceItem.discounted_revenue_by_invoice(invoice)).to eq(10000)

        discount_1 = create(:discount, merchant: merchant, quantity: 3, discount: 20)
        discount_2 = create(:discount, merchant: merchant, quantity: 5, discount: 50)

        # test that it returns full revenue if no discounts apply
        expect(InvoiceItem.discounted_revenue_by_invoice(invoice)).to eq(10000)

        # test that it finds the best discount.
        invoice_item_2 = create(:invoice_item, quantity: 2, unit_price: 10000, item: item_1, invoice: invoice)
        expect(InvoiceItem.discounted_revenue_by_invoice(invoice)).to eq(24000)

        # test that it finds the best discount. This will increase quantity to qualify for better discount
        invoice_item_3 = create(:invoice_item, quantity: 2, unit_price: 10000, item: item_1, invoice: invoice)
        expect(InvoiceItem.discounted_revenue_by_invoice(invoice)).to eq(25000)

        #test that it finds the best discount per item and sums across multiple items.
        item_2 = create(:item, merchant: merchant)
        invoice_item_4 = create(:invoice_item, quantity: 1, unit_price: 10000, item: item_2, invoice: invoice)
        invoice_item_5 = create(:invoice_item, quantity: 2, unit_price: 10000, item: item_2, invoice: invoice)
        expect(InvoiceItem.discounted_revenue_by_invoice(invoice)).to eq(49000)

        # test that it picks up the best discount for both items
        invoice_item_6 = create(:invoice_item, quantity: 3, unit_price: 10000, item: item_2, invoice: invoice)
        expect(InvoiceItem.discounted_revenue_by_invoice(invoice)).to eq(55000)

        #create items for another merchant and test that it picks up those properly.

        merchant_2 = create(:merchant)
        item_3 = create(:item, merchant: merchant_2)
        invoice_item_1 = create(:invoice_item, quantity: 1, unit_price: 10000, item: item_3, invoice: invoice)

        discount_3 = create(:discount, merchant: merchant_2, quantity: 4, discount: 10)
        discount_4 = create(:discount, merchant: merchant_2, quantity: 8, discount: 40)

        # test that it returns full revenue if no discounts apply
        expect(InvoiceItem.discounted_revenue_by_invoice(invoice)).to eq(65000)

        # test that it finds the best discount.
        invoice_item_2 = create(:invoice_item, quantity: 3, unit_price: 10000, item: item_3, invoice: invoice)
        expect(InvoiceItem.discounted_revenue_by_invoice(invoice)).to eq(91000)

        # test that it finds the best discount. This will increase quantity to qualify for better discount
        invoice_item_3 = create(:invoice_item, quantity: 5, unit_price: 10000, item: item_3, invoice: invoice)
        expect(InvoiceItem.discounted_revenue_by_invoice(invoice)).to eq(109000)

        #test that it finds the best discount per item and sums across multiple items.
        item_4 = create(:item, merchant: merchant_2)
        invoice_item_2 = create(:invoice_item, quantity: 1, unit_price: 10000, item: item_4, invoice: invoice)
        invoice_item_3 = create(:invoice_item, quantity: 3, unit_price: 10000, item: item_4, invoice: invoice)
        expect(InvoiceItem.discounted_revenue_by_invoice(invoice)).to eq(145000)

        # test that it picks up the best discount for both items
        invoice_item_3 = create(:invoice_item, quantity: 5, unit_price: 10000, item: item_4, invoice: invoice)
        expect(InvoiceItem.discounted_revenue_by_invoice(invoice)).to eq(163000)
      end
    end
  end
end
