require "application_system_test_case"

class JoinsTest < ApplicationSystemTestCase
  test "an owner shares the join link, and a new person joins through it" do
    owner = create(:identity, name: "Carla")
    Account.create_with_owner(name: "Edifício Aurora", owner:)
    sign_in_as(owner)

    visit "/accounts/edificio-aurora/"
    click_on "Share the join link"
    join_link = find_field("Join link").value
    visit "/accounts/edificio-aurora/"
    click_on "Sign out"

    visit join_link
    assert_selector "h1", text: "Join Edifício Aurora"
    fill_in "Email address", with: "ana@example.com"
    click_on "Continue"

    assert_text "Check your email"
    # Emails are queued, not sent, in tests, so the code comes from the database.
    fill_in "Code", with: MagicLink.last.code
    click_on "Sign in"

    assert_text "You're joining as ana@example.com."
    fill_in "Your name", with: "Ana"
    click_on "Join Edifício Aurora"

    assert_current_path "/accounts/edificio-aurora/"
    assert_selector "h1", text: "Edifício Aurora"
    # With one account, the menu goes straight into it.
    click_on "Your accounts"
    assert_current_path "/accounts/edificio-aurora/"
  end
end
