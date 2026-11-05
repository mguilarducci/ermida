ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "minitest/mock"
require_relative "test_helpers/session_test_helper"
require "webmock/minitest"
require "vcr"
require "n_plus_one_control/minitest"
require "with_model/minitest"

# Tests never reach the network. WebMock blocks real HTTP except to the test server and to the chrome service
# system tests drive (CHROME_URL); a test that needs a real call records it once with VCR and replays it after.
chrome_host = URI(ENV["CHROME_URL"]).host if ENV["CHROME_URL"]
WebMock.disable_net_connect!(allow_localhost: true, allow: [chrome_host].compact)

VCR.configure do |config|
  config.cassette_library_dir = "test/cassettes"
  config.hook_into :webmock
  config.ignore_localhost = true
  config.ignore_hosts(*[chrome_host].compact)
end

# n_plus_one_control runs the block several times on purpose to count its queries, which Prosopite would report as
# an N+1
module PauseProsopiteInNPlusOneControl
  %i[assert_perform_constant_number_of_queries assert_perform_linear_number_of_queries].each do |assertion|
    define_method(assertion) do |*args, **kwargs, &block|
      Prosopite.pause { super(*args, **kwargs, &block) }
    end
  end
end

module ActiveSupport
  class TestCase
    include FactoryBot::Syntax::Methods
    include PauseProsopiteInNPlusOneControl

    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Fail any test that runs an N+1 query (config/initializers/prosopite.rb)
    setup { Prosopite.scan("#{self.class}##{name}") }
    teardown { Prosopite.finish }

    # Add more helper methods to be used by all tests here...
  end
end

ActiveSupport.on_load(:action_dispatch_integration_test) do
  setup { ActionController::Base.cache_store.clear }
end
