require "test_helper"

# A join code lets anyone who has it join, so Rails' logs never print it.
class JoinLinkLoggingTest < ActionDispatch::IntegrationTest
  setup { @account = create(:account, name: "Edifício Aurora") }

  test "the code is filtered from the parameters line and from a redirect to a join page" do
    post "/accounts/edificio-aurora/join/#{@account.join_code}", params: {join_request: {email_address: "ana@example.com"}}
    sign_in_code = MagicLink.last.code

    log = capture_controller_log do
      get "/accounts/edificio-aurora/join/#{@account.join_code}"
      post "/session/magic_link", params: {code: sign_in_code}
    end

    assert_includes log, %("code" => "[FILTERED]")
    assert_includes log, "Redirected to [FILTERED]"
    assert_not_includes log, @account.join_code
    assert_not_includes log, sign_in_code
  end

  test "parameters named code or join_code are filtered, and longer names that contain code are not" do
    filter = ActiveSupport::ParameterFilter.new(Rails.application.config.filter_parameters)

    assert_equal({"code" => "[FILTERED]", "join_code" => "[FILTERED]", "postcode" => "01310-100"},
      filter.filter("code" => "abcd", "join_code" => "abcd-efgh-ijkm", "postcode" => "01310-100"))
  end

  private

  def capture_controller_log
    output = StringIO.new
    ActionController::Base.stub(:logger, ActiveSupport::Logger.new(output)) { yield }
    output.string
  end
end
