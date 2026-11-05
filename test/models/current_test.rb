require "test_helper"

class CurrentTest < ActiveSupport::TestCase
  teardown { Current.reset }

  test "setting the session sets its identity" do
    session = create(:session)

    Current.session = session

    assert_equal session.identity, Current.identity
  end

  test "without an account there is no current user" do
    user = create(:user)

    Current.session = create(:session, identity: user.identity)

    assert_nil Current.user
  end

  test "with an account the current user is the identity's user in it" do
    user = create(:user)
    Current.session = create(:session, identity: user.identity)

    Current.account = user.account

    assert_equal user, Current.user
  end
end
