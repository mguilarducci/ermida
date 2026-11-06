require "test_helper"

class JoinFormTest < ActiveSupport::TestCase
  setup { @account = create(:account) }

  test "a person without a name gives one, and joins as an active, verified member" do
    identity = create(:identity, name: nil)
    form = JoinForm.new(account: @account, identity:, person_name: "Ana")

    assert form.person_name_needed?
    assert form.save
    assert_equal "Ana", identity.reload.name
    assert form.user.member?
    assert form.user.active
    assert form.user.verified_at
  end

  test "a person who has a name is not asked for one and joins keeping it" do
    identity = create(:identity, name: "Bruno")
    form = JoinForm.new(account: @account, identity:)

    assert_not form.person_name_needed?
    assert form.save
    assert_equal "Bruno", identity.reload.name
    assert_equal identity, form.user.identity
  end

  test "a person without a name who leaves it blank does not join" do
    identity = create(:identity, name: nil)
    form = JoinForm.new(account: @account, identity:, person_name: " ")

    assert_not form.save
    assert form.errors.added?(:person_name, :blank)
    assert_equal 0, @account.users.count
  end

  test "a name over 100 characters is refused on the name, and the person stays unnamed and out" do
    identity = create(:identity, name: nil)
    form = JoinForm.new(account: @account, identity:, person_name: "a" * 101)

    assert_not form.save
    assert form.errors.of_kind?(:person_name, :too_long)
    assert_nil identity.reload.name
    assert_equal 0, @account.users.count
  end
end
