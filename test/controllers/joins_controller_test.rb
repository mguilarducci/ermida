require "test_helper"

# Paths are literal: after a request inside an account, the test's url helpers would keep its slug.
class JoinsControllerTest < ActionDispatch::IntegrationTest
  include ActionMailer::TestHelper

  setup do
    @account = create(:account, name: "Edifício Aurora")
    @join_path = "/accounts/edificio-aurora/join/#{@account.join_code}"
    @confirmation_path = "#{@join_path}/membership/new"
  end

  test "an active user of the account who opens the join link goes straight into it" do
    identity = create(:user, account: @account).identity
    sign_in_as(identity)

    assert_no_difference("User.count") { get @join_path }

    assert_redirected_to "/accounts/edificio-aurora/"
  end

  test "opening the join link signed out shows the account and asks for an email, creating nothing" do
    assert_no_difference(%w[Identity.count User.count MagicLink.count]) { get @join_path }

    assert_response :success
    assert_select "h1", text: /Edifício Aurora/
    assert_select "form[action=?] input[type=email][name=?]", @join_path, "join_request[email_address]"
  end

  test "a code that is not the account's is not found" do
    get "/accounts/edificio-aurora/join/#{create(:account).join_code}"
    assert_response :not_found

    post "/accounts/edificio-aurora/join/wrong-code", params: {join_request: {email_address: "ana@example.com"}}
    assert_response :not_found
  end

  test "a join link without the account's slug goes to the account menu" do
    get "/join/#{@account.join_code}"

    assert_redirected_to "/session/menu"
  end

  test "a known and an unknown email both go to the code page and return to the confirmation" do
    create(:identity, email_address: "bruno@example.com")

    %w[ana@example.com bruno@example.com].each do |email_address|
      post @join_path, params: {join_request: {email_address:}}

      assert_redirected_to "/session/magic_link"
      assert_equal @confirmation_path, session[:return_to_after_authenticating]
    end
  end

  test "the code sent from the join page signs the person in and returns to the confirmation" do
    post @join_path, params: {join_request: {email_address: "ana@example.com"}}

    post "/session/magic_link", params: {code: MagicLink.last.code}

    assert_redirected_to @confirmation_path
    assert cookies[:session_id].present?
  end

  test "a signed-in person who types their own email goes to the confirmation without a code" do
    identity = create(:identity, email_address: "ana@example.com")
    sign_in_as(identity)

    assert_no_enqueued_emails do
      post @join_path, params: {join_request: {email_address: " Ana@Example.com "}}
    end

    assert_redirected_to @confirmation_path
    assert_equal 1, identity.sessions.count
    assert cookies[:session_id].present?
  end

  test "a signed-in person who types another email is signed out, and the code goes to that email" do
    ana = create(:identity, email_address: "ana@example.com")
    sign_in_as(ana)
    ana_cookie = cookies[:session_id]

    assert_enqueued_emails 1 do
      post @join_path, params: {join_request: {email_address: "bruno@example.com"}}
    end

    assert_redirected_to "/session/magic_link"
    assert_equal 0, ana.sessions.count
    assert_equal 1, Identity.find_by!(email_address: "bruno@example.com").magic_links.count

    cookies[:session_id] = ana_cookie
    get "/session/menu"
    assert_redirected_to "/session/new"
  end

  test "a signed-in person who types a malformed email stays signed in and sees the error" do
    identity = create(:identity)
    sign_in_as(identity)

    post @join_path, params: {join_request: {email_address: "not an email"}}

    assert_response :unprocessable_content
    assert_select "input[name=?][aria-invalid=true]", "join_request[email_address]"
    assert_equal 1, identity.sessions.count
  end

  test "the 11th email within 3 minutes from one address goes back to the join page with a message" do
    # The same request ten times reads the same rows each time, which Prosopite would report as an N+1.
    Prosopite.pause { 10.times { post @join_path, params: {join_request: {email_address: "ana@example.com"}} } }

    assert_no_enqueued_emails do
      post @join_path, params: {join_request: {email_address: "ana@example.com"}}
    end

    assert_redirected_to @join_path
    assert_equal "Too many attempts. Try again in a few minutes.", flash[:alert]
  end
end
