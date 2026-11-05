class SessionsController < ApplicationController
  include Authentication::ViaMagicLink

  disallow_account_scope
  require_unauthenticated_access only: %i[new create]
  rate_limit to: 10, within: 3.minutes, only: :create, with: :rate_limit_exceeded

  def new
    @sign_in = SignInForm.new
  end

  def create
    @sign_in = SignInForm.new(sign_in_params)
    @sign_in.save
    redirect_to_session_magic_link(@sign_in.email_address, @sign_in.magic_link)
  end

  def destroy
    terminate_session
    redirect_to new_session_path, status: :see_other
  end

  private

  def sign_in_params = params.expect(sign_in: [:email_address])

  def rate_limit_exceeded
    redirect_to new_session_path, alert: t("sessions.rate_limited"), status: :see_other
  end
end
