require "test_helper"

class MagicLinkMailerTest < ActionMailer::TestCase
  test "the sign-in email carries the code in its subject and body, and no link" do
    link = create(:magic_link, purpose: :sign_in)

    email = MagicLinkMailer.sign_in_instructions(link)

    assert_equal [link.identity.email_address], email.to
    assert_includes email.subject, link.code
    assert_includes email.text_part.body.to_s, link.code
    assert_includes email.html_part.body.to_s, link.code
    assert_includes email.text_part.body.to_s, "sign in"
    assert_no_match(%r{https?://}, email.text_part.body.to_s)
    assert_no_match(/href=/, email.html_part.body.to_s)
  end

  test "the sign-up email asks to finish creating the account" do
    link = create(:magic_link, purpose: :sign_up)

    email = MagicLinkMailer.sign_in_instructions(link)

    assert_includes email.text_part.body.to_s, "finish creating your account"
  end
end
