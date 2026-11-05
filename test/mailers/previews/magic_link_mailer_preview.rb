class MagicLinkMailerPreview < ActionMailer::Preview
  def sign_in_instructions
    MagicLinkMailer.sign_in_instructions(magic_link(:sign_in))
  end

  def sign_up_instructions
    MagicLinkMailer.sign_in_instructions(magic_link(:sign_up))
  end

  private

  def magic_link(purpose)
    MagicLink.new(identity: Identity.new(email_address: "ana@example.com"), code: "4F7K2M", purpose:)
  end
end
