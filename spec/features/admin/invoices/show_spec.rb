require 'rails_helper'

RSpec.describe 'Admin_Invoices Show Page' do
  it 'shows the invoice attributes and the customer full name' do
    customer_1 = create(:customer, first_name: 'Bob', last_name: "Smith")
    invoice = create(:invoice, customer: customer_1, created_at: "2022-01-06")

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
    item = create(:item_with_invoices, merchant: merchant, invoices: [invoice], invoice_quantity: 12)
    item2 = create(:item_with_invoices, merchant: merchant, invoices: [invoice], invoice_quantity: 9)

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

    within("#invoice_#{invoice.invoice_items.first.id}") do
      expect(page).to have_content("Status: shipped")
    end

    within("#invoice_#{invoice.invoice_items.second.id}") do
      expect(page).to have_content("Status: pending")
    end
  end
end
