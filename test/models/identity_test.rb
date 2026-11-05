require "test_helper"

class IdentityTest < ActiveSupport::TestCase
  test "the email address is stored stripped and lowercased, and is unique" do
    create(:identity, email_address: "ana@example.com")
    other = build(:identity, email_address: " Ana@Example.com ")

    assert_equal "ana@example.com", other.email_address
    assert_not other.save
    assert other.errors.added?(:email_address, :taken, value: "ana@example.com")
  end

  test "an address without @ is rejected" do
    identity = build(:identity, email_address: "ana.example.com")

    assert_not identity.valid?
    assert identity.errors.added?(:email_address, :invalid, value: "ana.example.com")
  end

  test "an identity can be saved without a name, since sign-up asks for it after the code" do
    assert create(:identity, name: nil).persisted?
  end

  test "a name longer than 100 characters is rejected" do
    identity = build(:identity, name: "a" * 101)

    assert_not identity.valid?
    assert identity.errors.added?(:name, :too_long, count: 100)
  end

  test "staff defaults to false" do
    assert_not create(:identity).staff
  end

  test "the user lookup finds the identity's user in an account" do
    identity = create(:identity)
    user = create(:user, identity:)
    elsewhere = create(:account)

    assert_equal user, identity.user_in(user.account)
    assert_nil identity.user_in(elsewhere)
    assert_nil identity.user_in(nil)
  end

  test "the user lookup skips a user that is inactive but still has the identity" do
    identity = create(:identity)
    user = create(:user, identity:)
    user.update_columns(active: false)

    assert_nil identity.user_in(user.account)
  end

  test "an identity that has a user cannot be deleted" do
    identity = create(:identity)
    create(:user, identity:)

    assert_raises(ActiveRecord::DeleteRestrictionError) { identity.destroy }
    assert Identity.exists?(identity.id)
    assert_equal 1, identity.users.count
  end

  test "deleting an identity without users deletes its sessions" do
    identity = create(:identity)
    create(:session, identity:)

    identity.destroy!

    assert_equal 0, Session.count
  end

  test "accounts lists the accounts where the identity has an active user, by name" do
    identity = create(:identity)
    bravo = create(:user, identity:, account: create(:account, name: "Bravo")).account
    alpha = create(:user, identity:, account: create(:account, name: "Alpha")).account
    create(:user, identity:).deactivate
    create(:account)

    assert_equal [alpha, bravo], identity.accounts.to_a
  end
end
