require "test_helper"

class AccountPolicyTest < ActiveSupport::TestCase
  test "allows listing and creating accounts without a signed-in user" do
    policy = AccountPolicy.new(Account, user: nil)

    assert policy.apply(:index?)
    assert policy.apply(:create?)
  end

  test "lets in only an active user of the account" do
    user = create(:user)

    assert AccountPolicy.new(user.account, user:).apply(:show?)
    assert_not AccountPolicy.new(create(:account), user:).apply(:show?)
    assert_not AccountPolicy.new(user.account, user: nil).apply(:show?)
    assert_not AccountPolicy.new(user.account, user: create(:user, :deactivated, account: user.account)).apply(:show?)
  end
end
