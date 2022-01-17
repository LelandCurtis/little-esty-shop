require 'rails_helper'

RSpec.describe Invoice, type: :model do
  describe 'relationships' do
    it { should belong_to(:customer)}
    it { should have_many(:invoice_items)}
    it { should have_many(:items).through(:invoice_items)}
    it { should have_many(:merchants).through(:items)}
    it { should have_many(:discounts).through(:merchants)}
    it { should have_many(:transactions)}
  end

  describe 'enum validation' do
    it { should define_enum_for(:status).with(["in progress", :cancelled, :completed])}
  end

  describe 'instance methods' do
    describe '#customer_name' do
      it 'displays a customers first and last name' do
        merchant1 = create(:merchant)
        customer = create(:customer, first_name: 'Bob', last_name: 'Dole')
        invoice1 = create(:invoice, customer: customer)
        item1 = create(:item, merchant: merchant1)
        invoice_item1 = create(:invoice_item, item_id: item1.id, invoice_id: invoice1.id)

        expect(invoice1.customer_name).to eq("Bob Dole")
      end
    end

    describe '#merchant_items' do
      it 'organizes an invoices items by a given merchant' do
        merchant_1 = create(:merchant, name: 'Bob')
        invoice_1 = create(:invoice)
        item_1 = create(:item_with_invoices, invoice_count: 1, name: 'Toy', merchant: merchant_1, invoices: [invoice_1])
        item_2 = create(:item_with_invoices, invoice_count: 1, name: 'Car', merchant: merchant_1, invoices: [invoice_1])

        expect(invoice_1.merchant_items(merchant_1)).to eq([item_1, item_2])
      end
    end

    describe '#merchant_invoice_items' do
      it 'organizes invoice items alphabetically by a given merchant' do
        merchant_1 = create(:merchant, name: 'Bob')
        invoice_1 = create(:invoice)
        item_1 = create(:item_with_invoices, name: 'Toy', merchant: merchant_1, invoices: [invoice_1])
        item_2 = create(:item_with_invoices, name: 'Apple', merchant: merchant_1, invoices: [invoice_1])
        item_3 = create(:item_with_invoices, name: 'Zed', merchant: merchant_1, invoices: [invoice_1])
        item_4 = create(:item_with_invoices, name: 'Candy', invoices: [invoice_1])
        ## dig into possible refactor with a different factory: need => see item_name, set merchant, set invoice, invoice_item variable

        expect(invoice_1.merchant_invoice_items(merchant_1)).to eq([item_2.invoice_items.first, item_1.invoice_items.first, item_3.invoice_items.first])
      end
    end

    describe '#revenue' do
      it 'reports potential revenue from all items on a given invoice if there is at least 1 successful transaction' do
        invoice1 = create(:invoice)
        item1 = create(:item_with_invoices, name: 'Toy', invoices: [invoice1], invoice_item_quantity: 3, invoice_item_unit_price: 15000)
        item2 = create(:item_with_invoices, name: 'Car', invoices: [invoice1], invoice_item_quantity: 5, invoice_item_unit_price: 20000)
        transaction_1 = create(:transaction, invoice: invoice1, result: 1)

        expect(invoice1.revenue).to eq(0)

        transaction_2 = create(:transaction, invoice: invoice1, result: 0)
        expect(invoice1.revenue).to eq(145000)
      end
    end

    describe '#revenue_by_merchant' do
      it "reports revenue associated with items that belong to a particular merchant that are on a particular invoice" do
        merchant_1 = create(:merchant)
        merchant_2 = create(:merchant)
        invoice1 = create(:invoice)
        item1 = create(:item_with_invoices, name: 'Toy', merchant: merchant_1, invoices: [invoice1], invoice_item_quantity: 3, invoice_item_unit_price: 15000)
        item2 = create(:item_with_invoices, name: 'Car', merchant: merchant_2, invoices: [invoice1], invoice_item_quantity: 5, invoice_item_unit_price: 20000)
        transaction_2 = create(:transaction, invoice: invoice1, result: 0)

        # revenue associated with this invoice should not be included in potential revenue calcs.
        invoice2 = create(:invoice)
        item3 = create(:item_with_invoices, name: 'Plane', merchant: merchant_1, invoices: [invoice2], invoice_item_quantity: 3, invoice_item_unit_price: 33000)
        item4 = create(:item_with_invoices, name: 'Yoyo', merchant: merchant_2, invoices: [invoice2], invoice_item_quantity: 5, invoice_item_unit_price: 77000)
        transaction_3 = create(:transaction, invoice: invoice2, result: 0)

        expect(invoice1.revenue_by_merchant(merchant_1)).to eq(45000)
        expect(invoice1.revenue_by_merchant(merchant_2)).to eq(100000)
      end
    end

    describe '#discounted_revenue_by_merchant' do
      it "reports the total discounted revenue for all items that belong to a particular merchant on an invoice " do
        merchant = create(:merchant, name: "Bob Barker")
        invoice = create(:invoice)
        item_1 = create(:item_with_invoices, name: 'Toy', merchant: merchant, invoices: [invoice], invoice_item_unit_price: 10000, invoice_item_quantity: 2)
        item_2 = create(:item_with_invoices, name: 'Boat', merchant: merchant, invoices: [invoice], invoice_item_unit_price: 15000, invoice_item_quantity: 5)
        item_3 = create(:item_with_invoices, name: 'Car', merchant: merchant, invoices: [invoice], invoice_item_unit_price: 20000, invoice_item_quantity: 10)
        transaction = create(:transaction, invoice: invoice, result: 0)
        discount_1 = create(:discount, merchant: merchant, quantity: 3, discount: 20)
        discount_2 = create(:discount, merchant: merchant, quantity: 9, discount: 50)

        # create another merchant with items to ensure this revenue is not included
        merchant_2 = create(:merchant)
        invoice_2 = create(:invoice, merchant: merchant_2)
        item_4 = create(:item_with_invoices, name: 'Bean Bag', merchant: merchant_2, invoices: [invoice_2], invoice_item_unit_price: 10000, invoice_item_quantity: 2)
        transaction_2 = create(:transaction, invoice: invoice_2, result: 0)

        expect(invoice.discounted_revenue_by_merchant(merchant)).to eq(180000)
      end
    end
  end
end
