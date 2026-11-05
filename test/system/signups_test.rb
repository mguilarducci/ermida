require "application_system_test_case"

class SignupsTest < ApplicationSystemTestCase
  test "signing up with the emailed code, naming the account, then signing out" do
    visit new_session_path
    click_on "New to Ermida? Create an account"

    fill_in "Email address", with: "ana@example.com"
    click_on "Email me a code"

    assert_text "Check your email"
    # Emails are queued, not sent, in tests, so the code comes from the database.
    fill_in "Code", with: MagicLink.last.code
    click_on "Sign in"

    fill_in "Your name", with: "Ana"
    fill_in "Account name", with: "Edifício Aurora"
    click_on "Create account"

    assert_text "Account created."
    assert_current_path "/accounts/edificio-aurora/"
    assert_selector "h1", text: "Edifício Aurora"

    click_on "Sign out"

    assert_current_path new_session_path
  end
end
