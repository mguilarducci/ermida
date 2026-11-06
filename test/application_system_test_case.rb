require "test_helper"
# A suite name of its own, so its coverage merges with the other tests' instead of replacing it
SimpleCov.command_name "test:system"
require "capybara/cuprite"
require_relative "test_helpers/system_session_test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  include SystemSessionTestHelper

  # Headless Chrome over CDP, no Selenium
  driven_by :cuprite, screen_size: [1400, 1400], options: {
    # How long Chrome may take to start. A cold GitHub runner went past 10 seconds on the first test
    process_timeout: ENV["CI"] ? 30 : 10,
    timeout: 10
  }
end
