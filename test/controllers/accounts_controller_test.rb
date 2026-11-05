require "test_helper"

class AccountsControllerTest < ActionDispatch::IntegrationTest
  test "the form asks for the person's name only when they have none" do
    sign_in_as(create(:identity, name: nil))
    get new_account_path
    assert_select "input[name=?]", "account[person_name]"

    sign_in_as(create(:identity, name: "Ana"))
    get new_account_path
    assert_select "input[name=?]", "account[person_name]", count: 0
    assert_select "input[name=?]", "account[name]"
  end

  test "an owner of one account creates a second, lands in it, and the menu lists both" do
    identity = create(:identity, name: "Ana")
    create(:user, identity:, account: create(:account, name: "Alpha"))
    sign_in_as(identity)

    post accounts_path, params: {account: {name: "Bravo"}}

    assert_redirected_to "/accounts/bravo/"
    get session_menu_path
    assert_select "li a", text: "Alpha"
    assert_select "li a", text: "Bravo"
  end

  test "an invalid form is shown again with its errors" do
    sign_in_as(create(:identity, name: nil))

    post accounts_path, params: {account: {name: "", person_name: ""}}

    assert_response :unprocessable_content
    assert_equal 0, Account.count
    assert_select "input[aria-invalid=true]", count: 2
  end

  test "the form under an account's slug goes to the home page" do
    identity = create(:identity)
    account = create(:user, identity:).account
    sign_in_as(identity)

    get "/accounts/#{account.slug}/accounts/new"

    assert_redirected_to "/"
  end
end
