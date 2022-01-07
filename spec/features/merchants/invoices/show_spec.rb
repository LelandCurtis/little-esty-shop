require 'rails_helper'

RSpec.describe 'merchants invoice show page' do
  #
  # before :each do
  #   merchant1 = create(:merchant, name: "Bob Barker")
  #   customer_1 = create(:customer, first_name: "Eric", last_name: "Mielke")
  #   invoice1 = create(:invoice, customer: @customer_1)
  #
  #   visit "/merchants/#{@merchant1.id}/invoices/#{@invoice1.id}"
  # end


  it 'displays all information related to that invoice' do
    merchant1 = create(:merchant, name: "Bob Barker")
    customer_1 = create(:customer, first_name: "Eric", last_name: "Mielke")
    invoice1 = create(:invoice, customer: customer_1)

    visit "/merchants/#{merchant1.id}/invoices/#{invoice1.id}"

    expect(page).to have_content("#{invoice1.id}'s Information")
    expect(page).to have_content("Merchant: Bob Barker")
    expect(page).to have_content("Status: in_progress")
    expect(page).to have_content("Created On: #{invoice1.created_at.strftime("%A, %B %d, %Y")}")
    expect(page).to have_content("Customer: Eric Mielke")
  end

  it 'displays the invoiced item name' do
    merchant1 = create(:merchant, name: "Bob Barker")
    invoice1 = create(:invoice)
    item = create(:item_with_invoices, merchant: merchant1, invoices: [invoice1], invoice_count: 1, name: 'Toy')

    visit "/merchants/#{merchant1.id}/invoices/#{invoice1.id}"

    within("#invoice_#{item.id}") do
      expect(page).to have_content('Item: Toy')
    end
  end

  it 'displays the quantity of the item ordered' do
    merchant1 = create(:merchant, name: "Bob Barker")
    invoice1 = create(:invoice)
    item = create(:item_with_invoices, merchant: merchant1, invoices: [invoice1], invoice_count: 1, name: 'Toy')

    visit "/merchants/#{merchant1.id}/invoices/#{invoice1.id}"

    within("#invoice_#{item.id}") do
      expect(page).to have_content("Quantity Ordered: 8")
    end
  end

  it 'displays the price the item sold for' do
    merchant1 = create(:merchant, name: "Bob Barker")
    invoice1 = create(:invoice)
    item = create(:item_with_invoices, merchant: merchant1, invoices: [invoice1], invoice_count: 1, name: 'Toy', invoice_item_unit_price: 15000)

    visit "/merchants/#{merchant1.id}/invoices/#{invoice1.id}"

    within("#invoice_#{item.id}") do
      expect(page).to have_content("Unit Price: $150.0")
    end
  end

  it 'displays the invoice item status' do
    merchant1 = create(:merchant, name: "Bob Barker")
    invoice1 = create(:invoice)
    item = create(:item_with_invoices, merchant: merchant1, invoices: [invoice1], invoice_count: 1, invoice_item_status: 2)

    visit "/merchants/#{merchant1.id}/invoices/#{invoice1.id}"

    within("#invoice_#{item.id}") do
      expect(page).to have_content("Status: shipped")
    end
  end

  it 'does not display any other merchants items information' do
    merchant1 = create(:merchant, name: "Bob Barker")
    invoice1 = create(:invoice)
    item = create(:item_with_invoices, name: 'Toy', merchant: merchant1, invoices: [invoice1])
    item2 = create(:item_with_invoices, name: 'Car', merchant: merchant1, invoices: [invoice1])
    item3 = create(:item_with_invoices, invoices: [invoice1])

    visit "/merchants/#{merchant1.id}/invoices/#{invoice1.id}"

    expect(page).to have_content(item.name)
    expect(page).to have_content(item2.name)
    expect(page).to_not have_content(item3.name)
  end

  it 'displays the total revenue that will be generated from the invoice' do
    merchant1 = create(:merchant, name: "Bob Barker")
    invoice1 = create(:invoice)
    item = create(:item_with_invoices, name: 'Toy', merchant: merchant1, invoices: [invoice1], invoice_item_unit_price: 15000)
    item2 = create(:item_with_invoices, name: 'Car', merchant: merchant1, invoices: [invoice1], invoice_item_unit_price: 20000)

    visit "/merchants/#{merchant1.id}/invoices/#{invoice1.id}"

    expect(page).to have_content("Total Potential Revenue")
    expect(page).to have_content("$350.0")
  end
end
