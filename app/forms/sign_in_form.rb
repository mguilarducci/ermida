# Sign-in's first step: sends a code to a known email. An unknown or malformed email gets no code and no email,
# and the person sees the same page, so the form never tells whether an email has an account.
class SignInForm < ApplicationForm
  attribute :email_address, :string

  attr_reader :magic_link

  after_commit :deliver_code

  def email_address = Identity.normalize_value_for(:email_address, super)

  private

  def submit!
    @magic_link = Identity.find_by(email_address:)&.create_magic_link(purpose: :sign_in)
  end

  def deliver_code
    if magic_link
      MagicLinkDelivery.sign_in_instructions(magic_link).deliver_later
    end
  end
end
