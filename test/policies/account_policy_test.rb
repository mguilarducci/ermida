require "test_helper"

class AccountPolicyTest < ActiveSupport::TestCase
  test "allows listing and creating accounts without a signed-in user" do
    policy = AccountPolicy.new(Account, user: nil)

    assert policy.apply(:index?)
    assert policy.apply(:create?)
  end
end
