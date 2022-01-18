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

    describe '.discounted_revenue' do
      it 'reports discounted revenue from all items on a given invoice if there is at least 1 successful transaction' do
        merchant = create(:merchant)
        invoice = create(:invoice)
        item_1 = create(:item, merchant: merchant)
        invoice_item_1 = create(:invoice_item, quantity: 1, unit_price: 10000, item: item_1, invoice: invoice)

        # edge case: no discounts should return full revenue
        transaction_2 = create(:transaction, invoice: invoice, result: 0)
        expect(InvoiceItem.all.discounted_revenue).to eq(10000)

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

    # describe '.discounted_revenue_by_item' do
    #   it 'reports discounted revenue from a particular item on a given invoice if there is at least 1 successful transaction' do
    #     merchant = create(:merchant)
    #     invoice = create(:invoice)
    #     item_1 = create(:item_with_invoices, merchant: merchant, name: 'Toy', invoices: [invoice], invoice_item_unit_price: 10000, invoice_item_quantity: 2)
    #     item_2 = create(:item_with_invoices, merchant: merchant, name: 'Boat', invoices: [invoice], invoice_item_unit_price: 15000, invoice_item_quantity: 5)
    #     item_3 = create(:item_with_invoices, merchant: merchant, name: 'Car', invoices: [invoice], invoice_item_unit_price: 20000, invoice_item_quantity: 10)
    #
    #     discount_1 = create(:discount, merchant: merchant, quantity: 3, discount: 20)
    #     discount_2 = create(:discount, merchant: merchant, quantity: 5, discount: 50)
    #
    #     #test for no transactions
    #     expect(InvoiceItem.all.discounted_revenue_by_item(item_2)).to eq(0)
    #
    #     # test that it doesn't count revenue with unsuccessful transactions
    #     transaction_1 = create(:transaction, invoice: invoice, result: 1)
    #     expect(InvoiceItem.discounted_revenue_by_item(item_2)).to eq(0)
    #
    #     # test that it only counts revenue with successful transactions
    #     transaction_2 = create(:transaction, invoice: invoice, result: 0)
    #     expect(InvoiceItem.discounted_revenue_by_item(item_1)).to eq(20000)
    #     expect(InvoiceItem.discounted_revenue_by_item(item_2)).to eq(37500)
    #     expect(InvoiceItem.discounted_revenue_by_item(item_3)).to eq(100000)
    #   end
    # end

    describe '.total_discounted_revenue' do
      it 'reports discounted revenue from all items on a given invoice if there is at least 1 successful transaction' do
        merchant = create(:merchant)
        invoice = create(:invoice)
        item_1 = create(:item_with_invoices, merchant: merchant, name: 'Toy', invoices: [invoice], invoice_item_unit_price: 10000, invoice_item_quantity: 2)
        item_2 = create(:item_with_invoices, merchant: merchant, name: 'Boat', invoices: [invoice], invoice_item_unit_price: 15000, invoice_item_quantity: 5)
        item_3 = create(:item_with_invoices, merchant: merchant, name: 'Car', invoices: [invoice], invoice_item_unit_price: 20000, invoice_item_quantity: 10)

        discount_1 = create(:discount, merchant: merchant, quantity: 3, discount: 20)
        discount_2 = create(:discount, merchant: merchant, quantity: 5, discount: 50)

        # test that it only counts revenue with successful transactions
        transaction_2 = create(:transaction, invoice: invoice, result: 0)
        expect(InvoiceItem.total_discounted_revenue).to eq(157500)
      end
    end
  end
end
