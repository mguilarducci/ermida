# A join page's email step: sends a sign-in code to the email, creating the person when the email is new, so the
# page answers the same for a known and an unknown email. The code is a sign-in code, so the code page returns to
# the join link's confirmation, and the email is the usual code email, which names no account.
class JoinRequestForm < ApplicationForm
  attribute :email_address, :string

  attr_reader :identity, :magic_link

  after_commit :deliver_code

  def email_address = Identity.normalize_value_for(:email_address, super)

  def from?(identity) = identity.present? && identity.email_address == email_address

  def save
    super
  rescue ActiveRecord::RecordInvalid => error
    errors.merge!(error.record.errors)
    false
  end

  private

  # The magic link is nil once the email reached its code limit: the person sees the same page and gets no email.
  def submit!
    @identity = Identity.find_or_create_by_email_address(email_address)

    if identity.persisted?
      @magic_link = identity.create_magic_link(purpose: :sign_in)
    else
      raise ActiveRecord::RecordInvalid, identity
    end
  end

  def deliver_code
    if magic_link
      MagicLinkDelivery.sign_in_instructions(magic_link).deliver_later
    end
  end
end
