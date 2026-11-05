require "test_helper"

class AccountsControllerTest < ActionDispatch::IntegrationTest
  test "the home page lists the person's accounts" do
    identity = create(:identity)
    create(:user, identity:, account: create(:account, name: "Edifício Aurora"))
    sign_in_as(identity)

    get root_path

    assert_response :success
    assert_select "li", text: "Edifício Aurora"
  end

  test "a person with no accounts sees the way to create one" do
    sign_in_as(create(:identity))

    get root_path

    assert_response :success
    assert_select "a[href=?]", new_account_path
  end

  test "the home page offers to sign out" do
    sign_in_as(create(:identity))

    get root_path

    assert_select "form[action=?] button", session_path
  end

  test "a signed-out visit to the home page goes to sign-in" do
    get root_path

    assert_redirected_to new_session_path
  end

  test "the form asks for the person's name only when they have none" do
    sign_in_as(create(:identity, name: nil))
    get new_account_path
    assert_select "input[name=?]", "account[person_name]"

    sign_in_as(create(:identity, name: "Ana"))
    get new_account_path
    assert_select "input[name=?]", "account[person_name]", count: 0
    assert_select "input[name=?]", "account[name]"
  end

  test "an owner of one account creates a second, and the home page lists both" do
    identity = create(:identity, name: "Ana")
    create(:user, identity:, account: create(:account, name: "Alpha"))
    sign_in_as(identity)

    post accounts_path, params: {account: {name: "Bravo"}}

    assert_redirected_to root_path
    follow_redirect!
    assert_select "li", text: "Alpha"
    assert_select "li", text: "Bravo"
  end

  test "an invalid form is shown again with its errors" do
    sign_in_as(create(:identity, name: nil))

    post accounts_path, params: {account: {name: "", person_name: ""}}

    assert_response :unprocessable_content
    assert_equal 0, Account.count
    assert_select "input[aria-invalid=true]", count: 2
  end
end
