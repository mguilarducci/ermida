class SignupsController < ApplicationController
  include Authentication::ViaMagicLink

  allow_unauthenticated_access
  before_action :redirect_signed_in_person_to_account_form
  rate_limit to: 10, within: 3.minutes, only: :create, with: :rate_limit_exceeded

  def new
    @identity = Identity.new
  end

  def create
    @identity = Identity.find_or_create_by_email_address(email_address)

    if @identity.persisted?
      if (magic_link = @identity.create_magic_link(purpose: :sign_up))
        MagicLinkDelivery.sign_in_instructions(magic_link).deliver_later
        redirect_to_session_magic_link(magic_link)
      else
        redirect_to_fake_session_magic_link(@identity.email_address)
      end
    else
      render :new, status: :unprocessable_content
    end
  end

  private

  def email_address = params.expect(signup: [:email_address])[:email_address]

  def redirect_signed_in_person_to_account_form
    redirect_to new_account_path if authenticated?
  end

  def rate_limit_exceeded
    redirect_to new_signup_path, alert: t("sessions.rate_limited"), status: :see_other
  end
end
