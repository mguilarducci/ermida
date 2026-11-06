require "test_helper"

class SignupsControllerTest < ActionDispatch::IntegrationTest
  include ActionMailer::TestHelper

  test "the sign-up page asks for an email" do
    get new_signup_path

    assert_response :success
    assert_select "form[action=?] input[type=email][name=?]", signup_path, "signup[email_address]"
  end

  test "a new email creates a nameless identity and one sign-up code, and goes to the code page" do
    assert_enqueued_emails 1 do
      post signup_path, params: {signup: {email_address: "ana@example.com"}}
    end

    assert_redirected_to session_magic_link_path
    identity = Identity.find_by!(email_address: "ana@example.com")
    assert_nil identity.name
    assert_equal 1, identity.magic_links.for_sign_up.count
  end

  test "a known email creates no new identity and one sign-up code" do
    identity = create(:identity, email_address: "ana@example.com")

    assert_no_difference "Identity.count" do
      post signup_path, params: {signup: {email_address: "ana@example.com"}}
    end

    assert_equal 1, identity.magic_links.for_sign_up.count
  end

  test "an invalid email shows the form again with an error and creates nothing" do
    assert_no_difference %w[Identity.count MagicLink.count] do
      post signup_path, params: {signup: {email_address: "not an email"}}
    end

    assert_response :unprocessable_content
    assert_select "input[name=?][aria-invalid=true]", "signup[email_address]"
  end

  test "the sign-up code leads to the account form, signed in" do
    post signup_path, params: {signup: {email_address: "ana@example.com"}}

    post session_magic_link_path, params: {code: MagicLink.last.code}

    assert_redirected_to new_account_path
    assert cookies[:session_id].present?
  end

  test "a new email, the code and both names give an account owned by that person" do
    post signup_path, params: {signup: {email_address: "ana@example.com"}}
    post session_magic_link_path, params: {code: MagicLink.last.code}

    post accounts_path, params: {account: {person_name: "Ana", name: "Edifício Aurora"}}

    account = Account.find_by!(name: "Edifício Aurora")
    assert_equal "ana@example.com", account.users.owner.sole.identity.email_address
    assert_equal 1, account.users.system.count
    assert_redirected_to "/accounts/edificio-aurora/"
    follow_redirect!
    assert_select "h1", text: "Edifício Aurora"
  end

  test "a signed-in person opening the sign-up page goes straight to the account form" do
    sign_in_as(create(:identity))

    get new_signup_path

    assert_redirected_to new_account_path
  end

  test "the sign-up page under an account's slug goes to the home page" do
    create(:account, name: "Edifício Aurora")

    get "/accounts/edificio-aurora/signup/new"

    assert_redirected_to "/"
  end

  test "an email posted to sign-up under an account's slug goes to the home page and creates nothing" do
    create(:account, name: "Edifício Aurora")

    assert_no_enqueued_emails do
      assert_no_difference %w[Identity.count MagicLink.count] do
        post "/accounts/edificio-aurora/signup", params: {signup: {email_address: "ana@example.com"}}
      end
    end

    assert_redirected_to "/"
  end

  test "the sign-in page links to sign-up" do
    get new_session_path

    assert_select "a[href=?]", new_signup_path
  end

  test "sign-up codes count toward the same 5-per-15-minutes limit as sign-in codes" do
    identity = create(:identity, email_address: "ana@example.com")
    # The same request repeated reads the same rows each time, which Prosopite would report as an N+1.
    Prosopite.pause do
      5.times { |i| post session_path, params: {sign_in: {email_address: "ana@example.com"}}, env: {"REMOTE_ADDR" => "10.0.0.#{i}"} }
    end

    assert_no_enqueued_emails do
      post signup_path, params: {signup: {email_address: "ana@example.com"}}, env: {"REMOTE_ADDR" => "10.0.1.1"}
    end

    assert_redirected_to session_magic_link_path
    assert_equal 0, identity.magic_links.for_sign_up.count
  end

  test "the 11th sign-up within 3 minutes from one address is refused with a message and sends nothing" do
    # The same request ten times reads the same rows each time, which Prosopite would report as an N+1.
    Prosopite.pause { 10.times { post signup_path, params: {signup: {email_address: "ana@example.com"}} } }

    assert_no_enqueued_emails do
      post signup_path, params: {signup: {email_address: "ana@example.com"}}
    end

    assert_redirected_to new_signup_path
    assert_equal "Too many attempts. Try again in a few minutes.", flash[:alert]
  end
end
