require 'rails_helper'

RSpec.describe Item, type: :model do

  describe 'relationships' do
    it { should belong_to(:merchant) }
    it { should have_many(:discounts).through(:merchant) }
    it { should have_many(:invoice_items) }
    it { should have_many(:invoices).through(:invoice_items) }
    it { should have_many(:transactions).through(:invoices) }
  end

  describe 'validations' do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:description) }
    it { should validate_presence_of(:unit_price) }
    it { should validate_numericality_of(:unit_price) }
    it {should define_enum_for(:status).with([:Disabled, :Enabled])}
  end

  describe 'class methods' do
    it '#invoice_finder' do
      merchant1 = create(:merchant)
      invoice1 = create(:invoice)
      item1 = create(:item, merchant: merchant1)
      invoice_item1 = create(:invoice_item, item_id: item1.id, invoice_id: invoice1.id)
      expect(Item.invoice_finder(item1.merchant_id)).to eq [invoice1]
    end

    it '#enabled_items' do
      merchant = create(:merchant)
      item1 = create(:item, merchant: merchant, name: "Paul")
      item2 = create(:item, merchant: merchant, name: "Leland")
      item3 = create(:item, merchant: merchant, name: "Josh", status: 1)
      item4 = create(:item, merchant: merchant, name: "My mom", status: 1)

      expect(Item.enabled_items).to eq([item3, item4])
    end

    it '#disabled_items' do
      merchant = create(:merchant)
      item1 = create(:item, merchant: merchant, name: "Paul")
      item2 = create(:item, merchant: merchant, name: "Leland")
      item3 = create(:item, merchant: merchant, name: "Josh", status: 1)
      item4 = create(:item, merchant: merchant, name: "My mom", status: 1)

      expect(merchant.items.disabled_items).to eq([item1, item2])
    end
  end

  describe "instance methods" do
    describe 'revenue' do
      it "returns the revenue associated with that item. Only counts invoices that have valid transactions." do
        item_1 = create(:item_with_transactions, name: 'Toy', invoice_item_quantity: 3, invoice_item_unit_price: 15000, transaction_result: 1)
        expect(item_1.revenue).to eq(0)

        item_2 = create(:item_with_transactions, name: 'Car', invoice_item_quantity: 5, invoice_item_unit_price: 20000, transaction_result: 0)
        expect(item_2.revenue).to eq(100000)

        item_3 = create(:item_with_transactions, name: 'Desk', invoice_item_quantity: 2, invoice_item_unit_price: 20000, transaction_result: 0)
        item_3.invoice_items.update(item: item_2)
        expect(item_2.revenue).to eq(140000)
      end
    end

    describe 'best_day' do
      it "returns the date associated with the items highest revenue invoice" do
        merchant = create(:merchant)
        invoice_1 = create(:invoice, created_at: DateTime.new(2022, 1, 10, 1, 1, 1))
        item_1 = create(:item_with_transactions, merchant: merchant, name: "Toy", invoice: invoice_1, invoice_item_quantity: 4, invoice_item_unit_price: 100000)

        #create a smaller invoice that should not affect top date
        invoice_2 = create(:invoice, created_at: DateTime.new(2022, 1, 10, 1, 1, 1))
        item_2 = create(:item_with_transactions, merchant: merchant, name: "Toy", invoice: invoice_2, invoice_item_quantity: 2, invoice_item_unit_price: 1000)
        item_2.invoice_items.update(item: item_1)

        #create an equal revenue invoice that should not affect top date becuase it is older
        invoice_3 = create(:invoice, created_at: DateTime.new(2022, 1, 5, 1, 1, 1))
        item_3 = create(:item_with_transactions, merchant: merchant, name: "Toy", invoice: invoice_3, invoice_item_quantity: 4, invoice_item_unit_price: 100000)
        item_3.invoice_items.update(item: item_1)

        item_1.reload
        expect(item_1.best_day).to eq(DateTime.new(2022, 1, 10, 1, 1, 1))
      end
    end

    describe '#best_discount' do
      it "returns the best available discount for the chosen item" do
        merchant = create(:merchant)
        invoice = create(:invoice)
        item_1 = create(:item, merchant: merchant)
        invoice_item_1 = create(:invoice_item, quantity: 4, unit_price: 10000, item: item_1, invoice: invoice)
        transaction_1 = create(:transaction, invoice: invoice, result: 0)

        discount_1 = create(:discount, merchant: merchant, quantity: 3, discount: 20)
        discount_2 = create(:discount, merchant: merchant, quantity: 5, discount: 50)

        expect(item_1.best_discount).to eq(discount_1)

        # test increasing quantity of item to hit different discount
        invoice_item_2 = create(:invoice_item, quantity: 4, unit_price: 10000, item: item_1, invoice: invoice)
        expect(item_1.best_discount).to eq(discount_2)

        # test method when item is selected through relations
        invoice_items = invoice.merchant_invoice_items(merchant)
        invoice_items.each do |invoice_item|
          expect(invoice_item.item.best_discount).to eq(discount_2)
        end

        #test that it works with other data unrelated to the aprticular merchant or invoice
        merchant_2 = create(:merchant)
        invoice_2 = create(:invoice)
        item_1 = create(:item, merchant: merchant_2)
        invoice_item_3 = create(:invoice_item, quantity: 4, unit_price: 10000, item: item_1, invoice: invoice_2)
        transaction_2 = create(:transaction, invoice: invoice_2, result: 0)

        invoice_items_2 = invoice.merchant_invoice_items(merchant)
        invoice_items_2.each do |invoice_item|
          expect(invoice_item.item.best_discount).to eq(discount_2)
        end
      end
      
      it "returns nil if no discount qualifies" do
        merchant = create(:merchant)
        invoice = create(:invoice)
        item_1 = create(:item, merchant: merchant)
        invoice_item_1 = create(:invoice_item, quantity: 4, unit_price: 10000, item: item_1, invoice: invoice)
        transaction_1 = create(:transaction, invoice: invoice, result: 0)

        expect(item_1.best_discount).to eq(nil)

        discount_1 = create(:discount, merchant: merchant, quantity: 5, discount: 20)
        discount_2 = create(:discount, merchant: merchant, quantity: 6, discount: 50)

        expect(item_1.best_discount).to eq(nil)
      end
    end
  end
end
