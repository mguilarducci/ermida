require "test_helper"

class JoinLinkLogFilterTest < ActiveSupport::TestCase
  test "a join link's code is filtered from its path" do
    assert_equal "/accounts/edificio-aurora/join/[FILTERED]",
      JoinLinkLogFilter.call("/accounts/edificio-aurora/join/abcd-efgh-ijkm")
  end

  test "the confirmation's path keeps everything but the code" do
    assert_equal "/accounts/edificio-aurora/join/[FILTERED]/membership/new",
      JoinLinkLogFilter.call("/accounts/edificio-aurora/join/abcd-efgh-ijkm/membership/new")
  end

  test "a path without a join code stays as it is, and no path reads as empty" do
    assert_equal "/accounts/edificio-aurora/share", JoinLinkLogFilter.call("/accounts/edificio-aurora/share")
    assert_equal "", JoinLinkLogFilter.call(nil)
  end
end
