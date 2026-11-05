require "test_helper"

class MagicLinkTest < ActiveSupport::TestCase
  test "a new link gets a code from the alphabet and expires in 15 minutes" do
    freeze_time do
      link = create(:magic_link)

      assert_match(/\A[#{MagicLink::Code::ALPHABET.join}]{6}\z/o, link.code)
      assert_equal 15.minutes.from_now, link.expires_at
      assert link.for_sign_in?
    end
  end

  test "consuming the exact code returns the link and deletes it, so it works once" do
    link = create(:magic_link)

    assert_equal link, MagicLink.consume(link.code)
    assert_not MagicLink.exists?(link.id)
    assert_nil MagicLink.consume(link.code)
  end

  test "consuming accepts lowercase, spaces and look-alike letters" do
    link = create(:magic_link)
    link.update_columns(code: "10A2B0")

    assert_equal link, MagicLink.consume(" lo a2b o")
  end

  test "a link that another request already consumed is not consumed again" do
    link = create(:magic_link)
    stale_copy = MagicLink.find(link.id)
    link.consume

    assert_nil stale_copy.consume
  end

  test "an expired link is not consumed and stays in place" do
    link = create(:magic_link)

    travel 16.minutes do
      assert_nil MagicLink.consume(link.code)
    end
    assert MagicLink.exists?(link.id)
  end

  test "blank and unknown codes consume nothing" do
    create(:magic_link)

    assert_nil MagicLink.consume(nil)
    assert_nil MagicLink.consume("")
    assert_nil MagicLink.consume("ZZZZZZ")
  end

  test "a second link for the same identity leaves the first one usable" do
    identity = create(:identity)
    first = identity.create_magic_link(purpose: :sign_in)
    identity.create_magic_link(purpose: :sign_up)

    assert_equal first, MagicLink.consume(first.code)
  end

  test "cleanup deletes expired links and keeps active ones" do
    expired = create(:magic_link)
    expired.update_columns(expires_at: 1.minute.ago)
    active = create(:magic_link)

    MagicLink.cleanup

    assert_not MagicLink.exists?(expired.id)
    assert MagicLink.exists?(active.id)
  end
end
