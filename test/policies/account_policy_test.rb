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

  test "only an active owner or admin of the account sees the join link" do
    account = create(:account)

    assert AccountPolicy.new(account, user: create(:user, account:, role: :owner)).apply(:share?)
    assert AccountPolicy.new(account, user: create(:user, account:, role: :admin)).apply(:share?)
    assert_not AccountPolicy.new(account, user: create(:user, account:, role: :member)).apply(:share?)
    assert_not AccountPolicy.new(account, user: create(:user, account:, role: :provider)).apply(:share?)
    assert_not AccountPolicy.new(account, user: create(:user, role: :admin)).apply(:share?)
    assert_not AccountPolicy.new(account, user: create(:user, :deactivated, account:, role: :admin)).apply(:share?)
    assert_not AccountPolicy.new(account, user: nil).apply(:share?)
  end

  test "joining is for people who are not active users of the account" do
    account = create(:account)

    assert_not AccountPolicy.new(account, user: create(:user, account:)).apply(:join?)
    assert AccountPolicy.new(account, user: nil).apply(:join?)
    assert AccountPolicy.new(account, user: create(:user)).apply(:join?)
    assert AccountPolicy.new(account, user: create(:user, :deactivated, account:)).apply(:join?)
  end
end
