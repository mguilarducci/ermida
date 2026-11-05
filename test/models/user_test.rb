require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "a new user is an active member that is not verified" do
    user = create(:user)

    assert user.member?
    assert user.active
    assert_nil user.verified_at
  end

  test "every role saves" do
    %w[member provider admin owner system].each do |role|
      assert create(:user, role:).persisted?, role
    end
  end

  test "an unknown role is rejected" do
    user = build(:user, role: "janitor")

    assert_not user.valid?
    assert user.errors.added?(:role, :inclusion, value: "janitor")
  end

  test "a user without an account is rejected" do
    user = build(:user, account: nil)

    assert_not user.save
    assert user.errors.added?(:account, :blank)
  end

  test "a system user without an identity saves" do
    assert create(:user, :system).persisted?
  end

  test "an identity has one user per account" do
    identity = create(:identity)
    first = create(:user, identity:)
    create(:user, identity:)
    duplicate = build(:user, identity:, account: first.account)

    assert_not duplicate.save
    assert duplicate.errors.added?(:identity_id, :taken, value: identity.id)
  end

  test "deactivating clears the identity and frees its place in the account" do
    user = create(:user)
    identity = user.identity

    user.deactivate

    assert_not user.reload.active
    assert_nil user.identity
    assert create(:user, identity:, account: user.account).persisted?
  end

  test "users without an identity coexist in one account" do
    account = create(:account)
    create(:user, :system, account:)
    create(:user, :deactivated, account:)
    create(:user, :deactivated, account:)

    assert_equal 3, account.users.where(identity: nil).count
  end
end
