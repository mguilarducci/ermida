require "test_helper"

class BusinessTest < ActiveSupport::TestCase
  test "businesses sharing a name get sequential slugs" do
    slugs = 3.times.map { create(:business, name: "Padaria do João").slug }

    assert_equal %w[padaria-do-joao padaria-do-joao-2 padaria-do-joao-3], slugs
  end

  test "a new slug follows the highest suffix in use, leaving gaps unfilled" do
    create(:business, name: "Padaria do João")
    second = create(:business, name: "Padaria do João")
    create(:business, name: "Padaria do João")
    second.destroy!

    assert_equal "padaria-do-joao-4", create(:business, name: "Padaria do João").slug
  end

  test "route words get a suffix instead of becoming slugs" do
    assert_equal "new-2", create(:business, name: "New").slug
    assert_equal "edit-2", create(:business, name: "Edit").slug
  end

  test "renaming keeps the slug" do
    business = create(:business, name: "Padaria do João")

    business.update!(name: "Café Central")

    assert_equal "padaria-do-joao", business.reload.slug
  end

  test "a name without letters or digits is rejected on create" do
    business = build(:business, name: "!!!")

    assert_not business.save
    assert business.errors.added?(:name, :invalid)
  end

  test "a name without letters or digits is rejected on update" do
    business = create(:business)

    assert_not business.update(name: "!!!")
    assert business.errors.added?(:name, :invalid)
  end

  test "a name written only in a non-Latin alphabet is rejected" do
    business = build(:business, name: "Москва")

    assert_not business.valid?
    assert business.errors.added?(:name, :invalid)
  end

  test "a name made only of digits is accepted" do
    assert_equal "2024", create(:business, name: "2024").slug
  end

  test "a name longer than 100 characters is rejected" do
    business = build(:business, name: "a" * 101)

    assert_not business.valid?
    assert business.errors.added?(:name, :too_long, count: 100)
  end

  test "a name of exactly 100 characters is accepted" do
    assert build(:business, name: "a" * 100).valid?
  end

  test "a blank name is rejected" do
    business = build(:business, name: "  ")

    assert_not business.valid?
    assert business.errors.added?(:name, :blank)
  end

  test "deleting a business frees its slug" do
    first = create(:business, name: "Padaria do João")
    create(:business, name: "Padaria do João")
    first.destroy!

    assert_equal "padaria-do-joao", create(:business, name: "Padaria do João").slug
  end

  test "the slug drops accents, symbols and edge hyphens" do
    assert_equal "cafe-cao-ltda", create(:business, name: "Café & Ção  Ltda.").slug
  end

  test "the description is optional" do
    assert build(:business, description: nil).valid?
  end

  test "the slug is the URL parameter" do
    business = create(:business, name: "Padaria do João")

    assert_equal "padaria-do-joao", business.to_param
  end

  test "alphabetical orders by name" do
    %w[Charlie Alpha Bravo].each { |name| create(:business, name: name) }

    assert_equal %w[Alpha Bravo Charlie], Business.alphabetical.pluck(:name)
  end
end
