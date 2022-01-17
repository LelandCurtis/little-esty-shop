require 'rails_helper'

RSpec.describe 'merchant discount create page' do
  it "has a form to create a new discount and redirect to bulk discount index page" do
    merchant = create(:merchant)
    visit "/merchants/#{merchant.id}/discounts/new"

    within "div.new_discount" do
      fill_in("Percent Discount").with(10)
      fill_in "Quantity Threshold" with: 12
      click_button "Submit"
      expect(current_page).to eq("/merchants/#{merchant.id}/discounts")
    end

    visit "/merchants/#{merchant.id}/discounts"
    new_discount = Discount.last
    expect(page.has_css?("div.discount_#{new_discount.id}")).to eq(true)
  end

  it "reloads create form if invalid data submitted and shows flash message" do
    merchant = create(:merchant)
    visit "/merchants/#{merchant.id}/discounts/new"

    within "div.new_discount" do
      fill_in("Percent Discount").with(0)
      fill_in "Quantity Threshold" with: 0
      click_button "Submit"
      expect(current_page).to eq("/merchants/#{merchant.id}/discounts/new")
      expect(page).to have_content("Error: Invalid Data")
    end
  end
end
