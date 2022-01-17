require 'rails_helper'

RSpec.describe 'merchant_discount index page' do
  it "lists all discounts, including thier percentage discounts and quantity thresholds" do
    merchant = create(:merchant)
    discount_1 = create(:discount, merchant: merchant, quantity: 10, discount: 10)
    discount_2 = create(:discount, merchant: merchant, quantity: 12, discount: 15)

    visit "/merchants/#{merchant.id}/discounts"
    
    within "div.discount_#{discount_1.id}" do
      expect(page).to have_content("Discount ##{discount_1.id}")
      expect(page).to have_content("Percent Discount: 10%")
      expect(page).to have_content("Quantity Threshold: 10")
    end

    within "div.discount_#{discount_2.id}" do
      expect(page).to have_content("Discount ##{discount_2.id}")
      expect(page).to have_content("Percent Discount: 15%")
      expect(page).to have_content("Quantity Threshold: 12")
    end

  end
end
