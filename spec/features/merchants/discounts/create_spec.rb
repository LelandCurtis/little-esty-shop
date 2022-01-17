require 'rails_helper'

RSpec.describe 'merchant discount create page' do
  it "has a form to create a new discount and redirect to bulk discount index page" do
    merchant = create(:merchant)
    discount = create(:discount)
    visit "/merchants/#{merchant.id}/discounts/new"

    within "div.new_discount" do
      fill_in "Percent Discount:", with: 10
      fill_in "Quantity Threshold:", with: 12
      click_button "Create Bulk Discount"
      expect(current_path).to eq("/merchants/#{merchant.id}/discounts")
    end

    visit "/merchants/#{merchant.id}/discounts"
    new_discount = Discount.last
    expect(page.has_css?("div.discount_#{new_discount.id}")).to eq(true)
  end

  it "reloads create form if invalid data submitted and shows flash message" do
    merchant = create(:merchant)
    visit "/merchants/#{merchant.id}/discounts/new"

    within "div.new_discount" do
      fill_in "Percent Discount:", with: 0
      fill_in "Quantity Threshold:", with: 0
      click_button "Create Bulk Discount"
      expect(current_path).to eq("/merchants/#{merchant.id}/discounts/new")
    end
    
    expect(page).to have_content("Error: Quantity must be greater than 0 and Discount must be greater than 0")
  end
end
