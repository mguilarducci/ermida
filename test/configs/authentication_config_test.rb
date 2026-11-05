require "test_helper"

class AuthenticationConfigTest < ActiveSupport::TestCase
  test "the code page does not show the code by default" do
    assert_not AuthenticationConfig.new.show_code_on_page?
  end

  test "showing the code on the page refuses to load outside development" do
    assert_raises(Anyway::Config::ValidationError) { AuthenticationConfig.new(show_code_on_page: true) }
  end

  test "development may show the code on the page" do
    Rails.stub(:env, ActiveSupport::EnvironmentInquirer.new("development")) do
      assert AuthenticationConfig.new(show_code_on_page: true).show_code_on_page?
    end
  end
end
