require "test_helper"

class Sessions::MagicLinksControllerTest < ActionDispatch::IntegrationTest
  setup { @identity = create(:identity, email_address: "ana@example.com") }

  test "the code page without a pending email goes back to the sign-in page" do
    get session_magic_link_path

    assert_redirected_to new_session_path
  end

  test "a code submitted without a pending email is not used and starts no session" do
    link = @identity.create_magic_link(purpose: :sign_in)

    post session_magic_link_path, params: {code: link.code}

    assert_redirected_to new_session_path
    assert_equal 0, Session.count
    assert MagicLink.exists?(link.id)
  end

  test "the code page shows where the code went and asks for it" do
    request_code

    get session_magic_link_path

    assert_response :success
    assert_select "p", text: /ana@example.com/
    assert_select "input[name=code][autocomplete=one-time-code]"
  end

  test "signing in returns to the page the person was trying to reach" do
    get businesses_path
    request_code

    post session_magic_link_path, params: {code: last_code}

    assert_redirected_to businesses_path
    assert cookies[:session_id].present?
  end

  test "without a page to return to, signing in lands on the home page" do
    request_code

    post session_magic_link_path, params: {code: last_code}

    assert_redirected_to root_path
    assert_equal 1, @identity.sessions.count
  end

  test "a wrong code returns to the code page with an alert and starts no session" do
    request_code

    post session_magic_link_path, params: {code: "ZZZZZZ"}

    assert_redirected_to session_magic_link_path
    assert flash[:alert]
    assert_equal 0, Session.count
  end

  test "an expired code returns to the code page with an alert and stays stored" do
    request_code
    code = last_code

    travel 16.minutes do
      post session_magic_link_path, params: {code:}
    end

    assert_redirected_to session_magic_link_path
    assert flash[:alert]
    assert_equal 0, Session.count
    assert MagicLink.exists?(code:)
  end

  test "a code that belongs to someone else than the pending email starts no session" do
    other = create(:identity).create_magic_link(purpose: :sign_in)
    request_code

    post session_magic_link_path, params: {code: other.code}

    assert_redirected_to new_session_path
    assert_equal 0, Session.count
    assert cookies[:pending_authentication_token].blank?
  end

  test "a code works only once" do
    request_code
    code = last_code
    post session_magic_link_path, params: {code:}
    delete session_path
    request_code

    post session_magic_link_path, params: {code:}

    assert_redirected_to session_magic_link_path
  end

  test "a signed-in person opening the code page goes home" do
    sign_in_as(@identity)

    get session_magic_link_path

    assert_redirected_to root_path
  end

  test "the code never reaches the flash outside development" do
    request_code

    assert_nil flash[:magic_link_code]
  end

  test "the 11th code attempt within 15 minutes is refused with a message" do
    request_code
    # The same request ten times reads the same rows each time, which Prosopite would report as an N+1.
    Prosopite.pause { 10.times { post session_magic_link_path, params: {code: "ZZZZZZ"} } }

    post session_magic_link_path, params: {code: last_code}

    assert_redirected_to session_magic_link_path
    assert_equal "Too many attempts. Try again in a few minutes.", flash[:alert]
    assert_equal 0, Session.count
  end

  test "the 11th code attempt for one email within 15 minutes is refused even from different addresses" do
    request_code
    # The same request repeated reads the same rows each time, which Prosopite would report as an N+1.
    Prosopite.pause do
      10.times { |i| post session_magic_link_path, params: {code: "ZZZZZZ"}, env: {"REMOTE_ADDR" => "10.0.0.#{i}"} }
    end

    post session_magic_link_path, params: {code: last_code}, env: {"REMOTE_ADDR" => "10.0.1.1"}

    assert_redirected_to session_magic_link_path
    assert_equal "Too many attempts. Try again in a few minutes.", flash[:alert]
    assert_equal 0, Session.count
  end

  private

  def request_code
    post session_path, params: {email_address: @identity.email_address}
  end

  def last_code = @identity.magic_links.last.code
end
