require "test_helper"
require "capybara/cuprite"
require_relative "test_helpers/system_session_test_helper"

if ENV["CHROME_URL"]
  # The browser runs in another container: serve the app on every interface and point the browser at this
  # container's hostname (Rails adds the server port)
  Capybara.server_host = "0.0.0.0"
  Capybara.app_host = "http://#{Socket.gethostname}"
end

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  include SystemSessionTestHelper

  # Headless Chrome over CDP, no Selenium. With CHROME_URL set (a remote browser such as browserless),
  # Cuprite connects to it instead of launching Chrome.
  driven_by :cuprite, screen_size: [1400, 1400], options: {
    url: ENV["CHROME_URL"],
    process_timeout: 10,
    timeout: 10
  }.compact
end
