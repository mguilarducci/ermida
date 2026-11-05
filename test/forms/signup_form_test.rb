require "test_helper"

class SignupFormTest < ActiveSupport::TestCase
  include ActionMailer::TestHelper

  test "a new email creates a nameless identity with one sign-up code, emailed once the form commits" do
    form = SignupForm.new(email_address: " Ana@Example.com ")

    assert_enqueued_emails(1) { assert form.save }
    assert_equal "ana@example.com", form.identity.email_address
    assert_nil form.identity.name
    assert form.magic_link.for_sign_up?
  end

  test "a known email gets a sign-up code without a new identity" do
    identity = create(:identity, email_address: "ana@example.com")

    assert_no_difference("Identity.count") { assert SignupForm.new(email_address: "ana@example.com").save }
    assert_equal 1, identity.magic_links.for_sign_up.count
  end

  test "a malformed email is refused with the identity's error, and nothing is created or sent" do
    form = SignupForm.new(email_address: "not an email")

    assert_no_enqueued_emails do
      assert_no_difference(%w[Identity.count MagicLink.count]) { assert_not form.save }
    end
    assert form.errors.include?(:email_address)
  end

  test "an email past its code limit saves without a code or an email" do
    identity = create(:identity, email_address: "ana@example.com")
    # The same insert repeated runs the same uniqueness check each time, which Prosopite would report as an N+1.
    Prosopite.pause { MagicLink::ISSUE_LIMIT.times { identity.magic_links.create! } }
    form = SignupForm.new(email_address: "ana@example.com")

    assert_no_enqueued_emails { assert form.save }
    assert_nil form.magic_link
  end
end
