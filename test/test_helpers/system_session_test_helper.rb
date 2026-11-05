# Signs a system test's browser in by writing the session cookie straight into it.
module SystemSessionTestHelper
  def sign_in_as(identity)
    session = identity.sessions.create!
    cookie_jar = ActionDispatch::TestRequest.create.cookie_jar
    cookie_jar.signed[:session_id] = session.id

    # Open an app page first so the cookie gets this app's host, which differs when Chrome runs remotely.
    visit new_session_path
    page.driver.browser.cookies.set(
      name: "session_id",
      # Signed values are Base64 and can hold "+", which Rack would read back as a space unless escaped.
      value: CGI.escape(cookie_jar[:session_id]),
      domain: URI(page.current_url).host,
      path: "/",
      httponly: true
    )
  end
end
