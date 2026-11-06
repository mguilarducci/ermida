require "test_helper"

# Paths are literal: after a request inside an account, the test's url helpers would keep its slug.
class Joins::MembershipsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @account = create(:account, name: "Edifício Aurora")
    @join_path = "/accounts/edificio-aurora/join/#{@account.join_code}"
    @confirmation_path = "#{@join_path}/membership/new"
    @membership_path = "#{@join_path}/membership"
  end

  test "a new person proves their email, gives their name, confirms and lands in the account as a member" do
    post @join_path, params: {join_request: {email_address: "ana@example.com"}}
    post "/session/magic_link", params: {code: MagicLink.last.code}
    follow_redirect!
    assert_select "h1", text: /Edifício Aurora/
    assert_select "input[name=?]", "join[person_name]"

    post @membership_path, params: {join: {person_name: "Ana"}}

    assert_redirected_to "/accounts/edificio-aurora/"
    identity = Identity.find_by!(email_address: "ana@example.com")
    assert_equal "Ana", identity.name
    assert identity.user_in(@account).member?
    assert_nil session[:pending_join]
  end

  test "a person who has a name confirms without being asked for one" do
    identity = create(:identity, name: "Bruno")
    sign_in_as(identity)
    post @join_path, params: {join_request: {email_address: identity.email_address}}

    get @confirmation_path
    assert_select "input[name=?]", "join[person_name]", count: 0

    post @membership_path
    assert_redirected_to "/accounts/edificio-aurora/"
    assert identity.user_in(@account).member?
  end

  test "a blank name shows the confirmation again with the error" do
    identity = create(:identity, name: nil)
    sign_in_as(identity)
    post @join_path, params: {join_request: {email_address: identity.email_address}}

    post @membership_path, params: {join: {person_name: ""}}

    assert_response :unprocessable_content
    assert_select "input[name=?][aria-invalid=true]", "join[person_name]"
    assert_nil identity.user_in(@account)
  end

  test "signed out, the confirmation goes to sign-in and is where signing in returns to" do
    get @confirmation_path

    assert_redirected_to "/session/new"
    assert_equal @confirmation_path, session[:return_to_after_authenticating]
  end

  test "signed out, a confirmation with a wrong code also goes to sign-in, and is not found once signed in" do
    identity = create(:identity)
    wrong_confirmation_path = "/accounts/edificio-aurora/join/wrong-code/membership/new"

    get wrong_confirmation_path
    assert_redirected_to "/session/new"
    post "/session", params: {sign_in: {email_address: identity.email_address}}
    post "/session/magic_link", params: {code: identity.magic_links.last.code}
    assert_redirected_to wrong_confirmation_path

    follow_redirect!
    assert_response :not_found
  end

  test "a signed-in person who never typed their email on the join page goes back to it" do
    sign_in_as(create(:identity))

    get @confirmation_path

    assert_redirected_to @join_path
  end

  test "an email another person typed on this device sends the signed-in person back to the join page" do
    post @join_path, params: {join_request: {email_address: "ana@example.com"}}
    bruno = create(:identity, email_address: "bruno@example.com")
    sign_in_as(bruno)

    get @confirmation_path
    assert_redirected_to @join_path

    post @membership_path
    assert_redirected_to @join_path
    assert_nil bruno.user_in(@account)
  end

  test "confirming with the account's slug but a wrong code is not found and joins no one" do
    identity = create(:identity)
    sign_in_as(identity)
    post @join_path, params: {join_request: {email_address: identity.email_address}}

    assert_no_difference("User.count") do
      post "/accounts/edificio-aurora/join/wrong-code/membership"
    end

    assert_response :not_found
  end

  test "a former resident joins again as a new member" do
    former = create(:user, account: @account)
    identity = former.identity
    former.deactivate
    sign_in_as(identity)
    post @join_path, params: {join_request: {email_address: identity.email_address}}

    post @membership_path

    assert_redirected_to "/accounts/edificio-aurora/"
    assert_not_equal former, identity.user_in(@account)
    assert identity.user_in(@account).member?
  end

  test "an active user who opens the confirmation goes straight into the account" do
    sign_in_as(create(:user, account: @account).identity)

    get @confirmation_path

    assert_redirected_to "/accounts/edificio-aurora/"
  end
end
