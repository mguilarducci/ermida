require "test_helper"

class AccountFormTest < ActiveSupport::TestCase
  test "for a person who has a name, only the account name is required and their name stays" do
    identity = create(:identity, name: "Ana")
    form = AccountForm.new(identity:, name: "Edifício Aurora", person_name: "Someone else")

    assert form.save
    assert_equal "Edifício Aurora", form.account.name
    assert_equal "Ana", identity.reload.name
    assert_equal identity, form.account.users.owner.sole.identity
  end

  test "for a person without a name, a blank name is rejected and nothing is created" do
    identity = create(:identity, name: nil)
    form = AccountForm.new(identity:, name: "Edifício Aurora", person_name: "")

    assert_not form.save
    assert form.errors.added?(:person_name, :blank)
    assert_equal 0, Account.count
  end

  test "for a person without a name, saving stores the name on the person" do
    identity = create(:identity, name: nil)
    form = AccountForm.new(identity:, name: "Edifício Aurora", person_name: "Ana")

    assert form.save
    assert_equal "Ana", identity.reload.name
  end

  test "an account name that produces no slug shows the account's error and creates nothing" do
    identity = create(:identity, name: nil)
    form = AccountForm.new(identity:, name: "!!!", person_name: "Ana")

    assert_not form.save
    assert form.errors.added?(:name, :invalid)
    assert_equal 0, Account.count
    assert_nil identity.reload.name
  end
end
