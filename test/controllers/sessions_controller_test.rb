require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  test "the sign-in page opens without a session and says signing in is not available yet" do
    get new_session_path

    assert_response :success
    assert_select "h1", text: "Sign in"
    assert_select "p", text: "Signing in isn't available yet."
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
