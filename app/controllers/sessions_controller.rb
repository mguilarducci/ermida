class SessionsController < ApplicationController
  include Authentication::ViaMagicLink

  require_unauthenticated_access only: %i[new create]
  rate_limit to: 10, within: 3.minutes, only: :create, with: :rate_limit_exceeded

  def new
  end

  def create
    if (identity = Identity.find_by(email_address:))
      magic_link = identity.create_magic_link(purpose: :sign_in)
      MagicLinkDelivery.sign_in_instructions(magic_link).deliver_later
      redirect_to_session_magic_link(magic_link)
    else
      redirect_to_fake_session_magic_link(email_address)
    end
  end

  def destroy
    terminate_session
    redirect_to new_session_path, status: :see_other
  end

  private

  def email_address = params.expect(:email_address)

  def rate_limit_exceeded
    redirect_to new_session_path, alert: t("sessions.rate_limited"), status: :see_other
  end
end
