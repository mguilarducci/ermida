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
end
