require "application_system_test_case"

class BusinessesTest < ApplicationSystemTestCase
  test "creating, renaming and deleting a business" do
    visit businesses_path
    click_on "New business"

    fill_in "Name", with: "Padaria do João"
    fill_in "Description", with: "Fresh bread daily."
    click_on "Create Business"

    assert_text "Business created."
    assert_current_path "/businesses/padaria-do-joao"
    assert_text "Fresh bread daily."

    click_on "Edit"
    fill_in "Name", with: "Café Central"
    click_on "Update Business"

    assert_text "Business updated."
    assert_current_path "/businesses/padaria-do-joao"
    assert_selector "h1", text: "Café Central"

    accept_confirm { click_on "Delete" }

    assert_text "Business deleted."
    assert_current_path businesses_path
    assert_no_text "Café Central"
  end

  test "a blank name shows the error and keeps the description" do
    visit new_business_path

    fill_in "Description", with: "Fresh bread daily."
    click_on "Create Business"

    assert_text "Name can't be blank"
    assert_field "Description", with: "Fresh bread daily."
  end

  test "dismissing the delete confirmation keeps the business" do
    business = create(:business, name: "Padaria do João")

    visit business_path(business)
    dismiss_confirm { click_on "Delete" }

    assert_current_path "/businesses/padaria-do-joao"
    assert Business.exists?(business.id)
  end
end
