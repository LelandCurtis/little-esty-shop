require 'rails_helper'

RSpec.describe "Merchant Item Create page" do

  it "has a form for new item, and redirects to merchant items index with new item listed" do
    merchant1 = create(:merchant)
    visit "merchants/#{merchant1.id}/items/new"

    within('#create_item') do
      fill_in "Name:", with: "Paul's Item"
      fill_in "Description", with: "An item from Paul"
      fill_in "Unit Price:", with: 1000
      click_button "Create Item"
    end

    expect(current_path).to eq("/merchants/#{merchant1.id}/items")
    within("div.item_#{merchant1.items.last.id}") do
      expect(page).to have_content("Paul's Item")
    end
  end
end
