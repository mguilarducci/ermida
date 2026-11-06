require "test_helper"

class JoinRequestFormTest < ActiveSupport::TestCase
  include ActionMailer::TestHelper

  test "a new email creates the person with one sign-in code, emailed once the form commits" do
    form = JoinRequestForm.new(email_address: "ana@example.com")

    assert_enqueued_emails(1) { assert form.save }
    assert_equal "ana@example.com", form.identity.email_address
    assert form.magic_link.for_sign_in?
  end

  test "a known email gets a sign-in code without a new person" do
    identity = create(:identity, email_address: "ana@example.com")

    assert_no_difference("Identity.count") { assert JoinRequestForm.new(email_address: "ana@example.com").save }
    assert_equal 1, identity.magic_links.for_sign_in.count
  end

  test "a malformed email is refused with an error on it, and nothing is created or sent" do
    form = JoinRequestForm.new(email_address: "not an email")

    assert_no_enqueued_emails do
      assert_no_difference(%w[Identity.count MagicLink.count]) { assert_not form.save }
    end
    assert form.errors.include?(:email_address)
  end

  test "the email is normalized and recognizes the person it belongs to" do
    form = JoinRequestForm.new(email_address: " Ana@Example.com ")

    assert_equal "ana@example.com", form.email_address
    assert form.from?(create(:identity, email_address: "ana@example.com"))
    assert_not form.from?(create(:identity, email_address: "bruno@example.com"))
    assert_not form.from?(nil)
  end

  test "an email past its code limit saves without a code or an email" do
    identity = create(:identity, email_address: "ana@example.com")
    # The same insert repeated runs the same uniqueness check each time, which Prosopite would report as an N+1.
    Prosopite.pause { MagicLink::ISSUE_LIMIT.times { identity.magic_links.create! } }
    form = JoinRequestForm.new(email_address: "ana@example.com")

    assert_no_enqueued_emails { assert form.save }
    assert_nil form.magic_link
  end
end
