require 'rails_helper'

RSpec.describe 'Admin_Invoices Show Page' do
  it 'shows the invoice attributes and the customer full name' do
    customer_1 = create(:customer, first_name: 'Bob', last_name: "Smith")
    invoice = create(:invoice, customer: customer_1, created_at: "2022-01-06")
    item = create(:item_with_invoices, invoices: [invoice], invoice_item_unit_price: 13000)
    visit "/admin/invoices/#{invoice.id}"

    expect(page).to have_content(invoice.id)
    expect(page).to have_content(invoice.status)
    expect(page).to have_content("Thursday, January 06, 2022")
    expect(page).to have_content(invoice.customer_name)
  end

  it 'shows the invoiced items name' do
    merchant = create(:merchant)
    invoice = create(:invoice)
    item = create(:item_with_invoices, merchant: merchant, invoices: [invoice], name: 'Toy')
    item2 = create(:item_with_invoices, merchant: merchant, invoices: [invoice], name: 'Car')

    visit "/admin/invoices/#{invoice.id}"

    within("#invoice_#{invoice.invoice_items.first.id}") do
      expect(page).to have_content("Item: Toy")
    end

    within("#invoice_#{invoice.invoice_items.second.id}") do
      expect(page).to have_content("Item: Car")
    end
  end

  it 'shows the quantity of the item ordered' do
    merchant = create(:merchant)
    invoice = create(:invoice)
    item = create(:item_with_invoices, merchant: merchant, invoices: [invoice], invoice_item_quantity: 12)
    item2 = create(:item_with_invoices, merchant: merchant, invoices: [invoice], invoice_item_quantity: 9)

    visit "/admin/invoices/#{invoice.id}"

    within("#invoice_#{invoice.invoice_items.first.id}") do
      expect(page).to have_content("Quantity Ordered: 12")
    end

    within("#invoice_#{invoice.invoice_items.second.id}") do
      expect(page).to have_content("Quantity Ordered: 9")
    end
  end

  it 'shows the price the item sold for' do
    merchant = create(:merchant)
    invoice = create(:invoice)
    item = create(:item_with_invoices, merchant: merchant, invoices: [invoice], invoice_item_unit_price: 13000)
    item2 = create(:item_with_invoices, merchant: merchant, invoices: [invoice], invoice_item_unit_price: 24000)

    visit "/admin/invoices/#{invoice.id}"

    within("#invoice_#{invoice.invoice_items.first.id}") do
      expect(page).to have_content("Unit Price: $130.00")
    end

    within("#invoice_#{invoice.invoice_items.second.id}") do
      expect(page).to have_content("Unit Price: $240.00")
    end
  end

  it 'shows the invoice items status' do
    merchant = create(:merchant)
    invoice = create(:invoice)
    item = create(:item_with_invoices, merchant: merchant, invoices: [invoice], invoice_item_status: "shipped")
    item2 = create(:item_with_invoices, merchant: merchant, invoices: [invoice], invoice_item_status: "pending")

    visit "/admin/invoices/#{invoice.id}"

    within("#status_#{invoice.invoice_items.first.id}") do
      expect(page).to have_field(:status, with: "shipped")
    end

    within("#status_#{invoice.invoice_items.second.id}") do
      expect(page).to have_field(:status, with: "pending")
    end
  end

  it 'calculates the revenue of the invoice' do
    merchant = create(:merchant)
    invoice = create(:invoice)
    item = create(:item_with_invoices, merchant: merchant, invoices: [invoice], invoice_item_unit_price: 3000, invoice_item_quantity: 8)
    item2 = create(:item_with_invoices, merchant: merchant, invoices: [invoice], invoice_item_unit_price: 2500, invoice_item_quantity: 8)
    transaction = create(:transaction, invoice: invoice, result: 0)

    visit "/admin/invoices/#{invoice.id}"

    expect(page).to have_content("Total Potential Revenue")
    expect(page).to have_content("$440.00")
  end

  it 'calculates the discounted revenue of the invoice' do
    merchant = create(:merchant)
    invoice = create(:invoice)

    discount_1 = create(:discount, merchant: merchant, quantity: 3, discount: 20)
    discount_2 = create(:discount, merchant: merchant, quantity: 5, discount: 50)

    item_1 = create(:item, merchant: merchant)
    invoice_item_1 = create(:invoice_item, quantity: 1, unit_price: 10000, item: item_1, invoice: invoice)
    invoice_item_2 = create(:invoice_item, quantity: 2, unit_price: 10000, item: item_1, invoice: invoice)


    item_2 = create(:item, merchant: merchant)
    invoice_item_4 = create(:invoice_item, quantity: 1, unit_price: 10000, item: item_2, invoice: invoice)
    invoice_item_5 = create(:invoice_item, quantity: 2, unit_price: 10000, item: item_2, invoice: invoice)
    invoice_item_6 = create(:invoice_item, quantity: 3, unit_price: 10000, item: item_2, invoice: invoice)

    # create invoice_items for a different invoice that should not show up
    invoice_2 = create(:invoice)
    item_1 = create(:item, merchant: merchant)
    invoice_item_7 = create(:invoice_item, quantity: 10, unit_price: 1000000, item: item_1, invoice: invoice_2)

    visit "/admin/invoices/#{invoice.id}"

    expect(page).to have_content("Total Discounted Revenue")
    expect(page).to have_content("$54,000.00")
  end

  it 'displays invoice_items status and allows edits' do
    merchant = create(:merchant)
    invoice = create(:invoice)
    item = create(:item_with_invoices, merchant: merchant, invoices: [invoice])

    visit "/admin/invoices/#{invoice.id}"

    within("#status_#{invoice.invoice_items.first.id}") do
      expect(page).to have_field(:status, with: "pending")

      select 'packaged', from: :status
      click_on "Update Item Status"
      expect(current_path).to eq("/admin/invoices/#{invoice.id}")
      expect(page).to have_field(:status, with: "packaged")

      select 'shipped', from: :status
      click_on "Update Item Status"
      expect(current_path).to eq("/admin/invoices/#{invoice.id}")
      expect(page).to have_field(:status, with: "shipped")
    end
  end
end
