require "test_helper"

class AccountTest < ActiveSupport::TestCase
  test "accounts sharing a name get sequential slugs" do
    slugs = 2.times.map { create(:account, name: "Edifício Aurora").slug }

    assert_equal %w[edificio-aurora edificio-aurora-2], slugs
  end

  test "route words get a suffix instead of becoming slugs" do
    assert_equal "new-2", create(:account, name: "New").slug
    assert_equal "edit-2", create(:account, name: "Edit").slug
  end

  # Accounts live under /accounts/<slug>/, so a route word there left out of the list would let an account hide
  # that page. A route added under /accounts/ fails here until its word is reserved.
  test "every route word under /accounts/ is reserved" do
    words = Rails.application.routes.routes.filter_map { it.path.spec.to_s[%r{\A/accounts/([a-z0-9_-]+)}, 1] }.uniq

    assert_empty words - Account::RESERVED_SLUGS
  end

  test "renaming keeps the slug" do
    account = create(:account, name: "Edifício Aurora")

    account.update!(name: "Residencial Aurora")

    assert_equal "edificio-aurora", account.reload.slug
  end

  test "a blank name is rejected" do
    account = build(:account, name: "  ")

    assert_not account.valid?
    assert account.errors.added?(:name, :blank)
  end

  test "a name longer than 100 characters is rejected" do
    account = build(:account, name: "a" * 101)

    assert_not account.valid?
    assert account.errors.added?(:name, :too_long, count: 100)
  end

  test "a name without Latin letters or digits is rejected" do
    account = build(:account, name: "Москва")

    assert_not account.valid?
    assert account.errors.added?(:name, :invalid)
  end

  test "the id is a UUID" do
    assert_match(/\A\h{8}-\h{4}-7\h{3}-\h{4}-\h{12}\z/, create(:account).id)
  end

  test "a new account gets a join code" do
    assert_match(/\A\w{4}-\w{4}-\w{4}\z/, create(:account).join_code)
  end

  test "an account created with a join code keeps it" do
    assert_equal "abcd-efgh-ijkm", create(:account, join_code: "abcd-efgh-ijkm").join_code
  end

  test "an account recognizes only its own join code" do
    account = create(:account)

    assert account.join_code?(account.join_code)
    assert_not account.join_code?(create(:account).join_code)
  end

  test "two accounts never share a join code" do
    account = create(:account)
    duplicate = build(:account, join_code: account.join_code)

    assert_not duplicate.save
    assert duplicate.errors.added?(:join_code, :taken, value: account.join_code)
  end

  test "inspecting an account hides its join code" do
    account = create(:account)

    assert_no_match account.join_code, account.inspect
    assert_includes account.inspect, %(join_code: [FILTERED])
  end

  test "creating with an owner adds a system user and the owner, verified" do
    identity = create(:identity)

    account = Account.create_with_owner(name: "Edifício Aurora", owner: identity)

    assert account.persisted?
    assert_equal 1, account.users.system.count
    assert_nil account.users.system.first.identity
    owner = account.users.owner.sole
    assert_equal identity, owner.identity
    assert owner.verified_at
  end

  test "a person with no user in the account joins as an active, verified member" do
    account = create(:account)
    identity = create(:identity)

    user = account.join(identity)

    assert_equal [account, identity], [user.account, user.identity]
    assert user.member?
    assert user.active
    assert user.verified_at
  end

  test "an active user who joins again stays the same user" do
    user = create(:user)

    assert_no_difference -> { User.count } do
      assert_equal user, user.account.join(user.identity)
    end
  end

  test "an owner who joins keeps the owner role" do
    owner = create(:user, role: :owner)

    assert owner.account.join(owner.identity).owner?
  end

  test "a person whose user was deactivated joins as a new member" do
    former = create(:user, role: :admin)
    identity = former.identity
    former.deactivate

    user = former.account.join(identity)

    assert_not_equal former, user
    assert user.member?
    assert user.active
    assert_not former.reload.active
    assert_nil former.identity
  end

  test "joining needs a person" do
    account = create(:account)
    create(:user, :system, account:)

    assert_raises(ArgumentError) { account.join(nil) }
  end

  test "a person whose user a concurrent join created gets that user" do
    account = create(:account)
    identity = create(:identity)
    winner = nil
    user = nil
    active_users = account.users.active

    # The concurrent join inserts its user right after this join looked and found none.
    active_users.stub(:find_by, ->(**) {
      winner = create(:user, account:, identity:)
      nil
    }) do
      account.users.stub(:active, active_users) { user = account.join(identity) }
    end

    assert_equal winner, user
  end

  test "an inactive user that still holds the person is not reactivated by joining" do
    user = create(:user)
    user.update_columns(active: false)

    assert_raises(ActiveRecord::RecordNotFound) { user.account.join(user.identity) }
    assert_not user.reload.active
  end

  test "creating with an owner and a blank name raises and creates nothing" do
    identity = create(:identity)

    assert_raises(ActiveRecord::RecordInvalid) { Account.create_with_owner(name: " ", owner: identity) }
    assert_equal 0, Account.count
    assert_equal 0, User.count
  end
end
