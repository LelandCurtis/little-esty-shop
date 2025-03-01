require 'rails_helper'

RSpec.describe 'merchant_discount index page' do
  it "lists all discounts, including thier percentage discounts and quantity thresholds" do
    merchant = create(:merchant)
    visit "/merchants/#{merchant.id}/discounts"

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

  it "has a link to each discount show page" do
    merchant = create(:merchant)
    discount_1 = create(:discount, merchant: merchant, quantity: 10, discount: 10)

    visit "/merchants/#{merchant.id}/discounts"

    within "div.discount_#{discount_1.id}" do
      click_link "Discount ##{discount_1.id}"
      expect(current_path).to eq(merchant_discount_path(merchant, discount_1))
    end
  end

  it "has a link to create a new discount" do
    merchant = create(:merchant)

    visit visit "/merchants/#{merchant.id}/discounts"

    click_link "Create New Bulk Discount"

    expect(current_path).to eq("/merchants/#{merchant.id}/discounts/new")
  end

  it "has a link to delete each discount" do
    merchant = create(:merchant)
    discount_1 = create(:discount, merchant: merchant, quantity: 10, discount: 10)

    visit "/merchants/#{merchant.id}/discounts"

    within "div.discount_#{discount_1.id}" do
      click_button "Delete Discount ##{discount_1.id}"
      expect(current_path).to eq("/merchants/#{merchant.id}/discounts")
    end
    expect(page).to_not have_content("Discount ##{discount_1.id}")
  end

  it "has an Upcomming Holidays section with the name and date of the next three holidays" do
    merchant = create(:merchant)

    visit "/merchants/#{merchant.id}/discounts"

    upcomming_holidays = Holidays.new(3)

    within "div.upcomming_holidays" do
      upcomming_holidays.holidays.each do |holiday|
        expect(page).to have_content(holiday.name)
        expect(page).to have_content(holiday.date)
      end
    end
  end
end
