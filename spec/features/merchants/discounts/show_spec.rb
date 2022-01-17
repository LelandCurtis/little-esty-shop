require 'rails_helper'

RSpec.describe 'discount show page' do
  it "shows all content of discount" do
    merchant = create(:merchant)
    discount_1 = create(:discount, merchant: merchant, quantity: 12, discount: 10)

    visit merchant_discount_path(merchant, discount_1)

    expect(page).to have_content("Discount ##{discount_1.id}")
    expect(page).to have_content("Percent Discount: 10%")
    expect(page).to have_content("Quantity Threshold: 12")
    expect(page).to have_content("Merchant Name: #{merchant.name}")
  end
end
