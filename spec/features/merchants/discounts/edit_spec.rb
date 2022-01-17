require 'rails_helper'

RSpec.describe 'merchant discount edit form page' do
  it "has a form to edit a discount that is prepolulated with existing values and redirects to bulk discount show page" do
    merchant = create(:merchant)
    discount = create(:discount, merchant: merchant, quantity: 14, discount: 6)
    visit "/merchants/#{merchant.id}/discounts/#{discount.id}/edit"

    within "div.edit_discount" do
      expect(page).to have_field('Quantity Threshold:', with: 14)
      expect(page).to have_field('Percent Discount:', with: 6)
      expect(page).to have_field('Merchant ID:', with: merchant.id)

      fill_in "Percent Discount:", with: 10
      fill_in "Quantity Threshold:", with: 12
      click_button "Update Bulk Discount"
      expect(current_path).to eq("/merchants/#{merchant.id}/discounts/#{discount.id}")
    end

    visit "/merchants/#{merchant.id}/discounts"
    within "div.discount_#{discount.id}" do
      expect(page).to have_content("Percent Discount: 10%")
      expect(page).to have_content("Quantity Threshold: 12")
    end
  end

  it "redirects to edit page and displays error message if edit fails" do
    merchant = create(:merchant)
    discount = create(:discount, merchant: merchant, quantity: 14, discount: 6)
    visit "/merchants/#{merchant.id}/discounts/#{discount.id}/edit"

    within "div.edit_discount" do
      fill_in "Percent Discount:", with: 0
      fill_in "Quantity Threshold:", with: 0
      click_button "Update Bulk Discount"
      expect(current_path).to eq("/merchants/#{merchant.id}/discounts/#{discount.id}/edit")
    end
    expect(page).to have_content("Error: Quantity must be greater than 0 and Discount must be greater than 0")
  end
end
