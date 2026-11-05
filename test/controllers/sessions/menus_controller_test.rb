require "test_helper"

class Sessions::MenusControllerTest < ActionDispatch::IntegrationTest
  setup { @identity = create(:identity) }

  test "the menu links to each of the person's accounts" do
    alpha = create(:user, identity: @identity, account: create(:account, name: "Alpha")).account
    create(:user, identity: @identity, account: create(:account, name: "Bravo"))
    sign_in_as(@identity)

    get session_menu_path

    assert_response :success
    assert_select "li a[href=?]", "/accounts/#{alpha.slug}/", text: "Alpha"
    assert_select "li a", text: "Bravo"
  end

  test "a person with one account goes straight into it" do
    account = create(:user, identity: @identity).account
    sign_in_as(@identity)

    get session_menu_path

    assert_redirected_to "/accounts/#{account.slug}/"
  end

  test "an account the person left is not listed" do
    create(:user, :deactivated, identity: @identity)
    sign_in_as(@identity)

    get session_menu_path

    assert_response :success
    assert_select "li", count: 0
  end

  test "a person with no accounts sees the way to create one" do
    sign_in_as(@identity)

    get session_menu_path

    assert_select "a[href=?]", new_account_path
  end

  test "the menu offers to sign out" do
    sign_in_as(@identity)

    get session_menu_path

    assert_select "form[action=?] button", session_path
  end

  test "the home page outside an account leads to the menu" do
    sign_in_as(@identity)

    get root_path

    assert_redirected_to session_menu_path
  end

  test "a signed-out visit to the home page ends at sign-in" do
    get root_path
    follow_redirect!

    assert_redirected_to new_session_path
  end
end
