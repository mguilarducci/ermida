require "test_helper"

class LandingsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @account = create(:account, name: "Edifício Aurora")
    @identity = create(:identity)
  end

  test "an active user of the account opens it under its slug" do
    create(:user, identity: @identity, account: @account)
    sign_in_as(@identity)

    get "/accounts/edificio-aurora/"

    assert_response :success
    assert_select "h1", text: "Edifício Aurora"
  end

  test "a person who is not a user of the account goes back to the menu" do
    create(:user, identity: @identity)
    sign_in_as(@identity)

    get "/accounts/edificio-aurora/"

    assert_redirected_to "/session/menu"
  end

  test "a person who left the account goes back to the menu" do
    create(:user, :deactivated, identity: @identity, account: @account)
    sign_in_as(@identity)

    get "/accounts/edificio-aurora/"

    assert_redirected_to "/session/menu"
  end

  test "a slug that matches no account is not found" do
    sign_in_as(@identity)

    get "/accounts/nowhere/"

    assert_response :not_found
  end

  test "signing in from an account's page returns to it" do
    create(:user, identity: @identity, account: @account)

    get "/accounts/edificio-aurora/"
    assert_redirected_to "/session/new"
    # Paths are literal: after a request inside an account, the test's url helpers would keep its slug.
    post "/session", params: {sign_in: {email_address: @identity.email_address}}
    post "/session/magic_link", params: {code: @identity.magic_links.last.code}

    assert_redirected_to "/accounts/edificio-aurora/"
  end

  test "inside an account, the links to the menu and to sign out leave its slug" do
    create(:user, identity: @identity, account: @account)
    sign_in_as(@identity)

    get "/accounts/edificio-aurora/"

    assert_select "a[href=?]", "/session/menu"
    assert_select "form[action=?] button", "/session"
  end

  test "a page that belongs to no account, opened under an account's slug, goes to the home page" do
    create(:user, identity: @identity, account: @account)
    sign_in_as(@identity)

    get "/accounts/edificio-aurora/session/menu"

    assert_redirected_to "/"
  end
end
