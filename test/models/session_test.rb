require "test_helper"

class SessionTest < ActiveSupport::TestCase
  test "a session without an identity is rejected" do
    session = build(:session, identity: nil)

    assert_not session.save
    assert session.errors.added?(:identity, :blank)
  end
end
