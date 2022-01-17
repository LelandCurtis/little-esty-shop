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

  it "has a link to the edit form page" do
    merchant = create(:merchant)
    discount_1 = create(:discount, merchant: merchant, quantity: 12, discount: 10)

    visit merchant_discount_path(merchant, discount_1)

    click_link "Edit Bulk Discount"
    expect(current_path).to eq("/merchants/#{merchant.id}/discounts/#{discount_1.id}/edit")
  end
end
