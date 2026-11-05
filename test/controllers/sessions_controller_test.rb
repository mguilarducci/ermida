require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  include ActionMailer::TestHelper

  test "the sign-in page opens without a session and asks for an email" do
    get new_session_path

    assert_response :success
    assert_select "h1", text: "Sign in"
    assert_select "form[action=?] input[name=email_address]", session_path
  end

  test "a known email gets one sign-in code by email and goes to the code page" do
    identity = create(:identity, email_address: "ana@example.com")

    assert_enqueued_emails 1 do
      post session_path, params: {email_address: " Ana@Example.com "}
    end

    assert_redirected_to session_magic_link_path
    assert_equal 1, identity.magic_links.for_sign_in.count
  end

  test "an unknown email goes to the same code page, with nothing created and no email" do
    assert_no_enqueued_emails do
      assert_no_difference %w[Identity.count MagicLink.count] do
        post session_path, params: {email_address: "nobody@example.com"}
      end
    end

    assert_redirected_to session_magic_link_path
    follow_redirect!
    assert_response :success
  end

  test "an unknown email shows the same normalized address a known one would" do
    post session_path, params: {email_address: " Nobody@Example.com "}
    follow_redirect!

    assert_select "p", text: /nobody@example.com/
  end

  test "a malformed email is treated like an unknown one" do
    assert_no_enqueued_emails do
      post session_path, params: {email_address: "not an email"}
    end

    assert_redirected_to session_magic_link_path
  end

  test "a signed-in person opening the sign-in page goes home" do
    sign_in_as(create(:identity))

    get new_session_path

    assert_redirected_to root_path
  end

  test "the 11th email within 3 minutes from one address is refused with a message and sends nothing" do
    create(:identity, email_address: "ana@example.com")
    # The same request ten times reads the same rows each time, which Prosopite would report as an N+1.
    Prosopite.pause { 10.times { post session_path, params: {email_address: "ana@example.com"} } }

    assert_no_enqueued_emails do
      post session_path, params: {email_address: "ana@example.com"}
    end

    assert_redirected_to new_session_path
    assert_equal "Too many attempts. Try again in a few minutes.", flash[:alert]
  end

  test "signing out ends the session and returns to the sign-in page" do
    sign_in_as(create(:identity))

    delete session_path

    assert_redirected_to new_session_path
    assert_response :see_other
    assert_equal 0, Session.count
    assert_empty cookies[:session_id]
  end

  test "signing out without a session goes to the sign-in page" do
    delete session_path

    assert_redirected_to new_session_path
  end

  test "a page without a session redirects to the sign-in page" do
    get businesses_path

    assert_redirected_to new_session_path
  end

  test "a very long URL without a session still redirects to the sign-in page" do
    get businesses_path(q: "x" * 5000)

    assert_redirected_to new_session_path
  end

  test "a cookie pointing at a deleted session counts as signed out" do
    sign_in_as(create(:identity))
    Session.delete_all

    get businesses_path

    assert_redirected_to new_session_path
  end
end
