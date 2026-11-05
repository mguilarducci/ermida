require "test_helper"

class SignInFormTest < ActiveSupport::TestCase
  include ActionMailer::TestHelper

  test "a known email gets one sign-in code, emailed once the form commits" do
    identity = create(:identity, email_address: "ana@example.com")
    form = SignInForm.new(email_address: " Ana@Example.com ")

    assert_enqueued_emails(1) { assert form.save }
    assert_equal identity, form.magic_link.identity
    assert form.magic_link.for_sign_in?
  end

  test "an unknown email saves the same way, with no code and no email" do
    form = SignInForm.new(email_address: "nobody@example.com")

    assert_no_enqueued_emails do
      assert_no_difference(%w[Identity.count MagicLink.count]) { assert form.save }
    end
    assert_nil form.magic_link
  end

  test "the email reads normalized like an identity's" do
    assert_equal "nobody@example.com", SignInForm.new(email_address: " Nobody@Example.com ").email_address
  end
end
