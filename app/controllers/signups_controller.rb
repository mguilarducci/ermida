class SignupsController < ApplicationController
  include Authentication::ViaMagicLink

  disallow_account_scope
  allow_unauthenticated_access
  before_action :redirect_signed_in_person_to_account_form
  rate_limit to: 10, within: 3.minutes, only: :create, with: :rate_limit_exceeded

  def new
    @signup = SignupForm.new
  end

  def create
    @signup = SignupForm.new(signup_params)

    if @signup.save
      redirect_to_session_magic_link(@signup.identity.email_address, @signup.magic_link)
    else
      render :new, status: :unprocessable_content
    end
  end

  private

  def signup_params = params.expect(signup: [:email_address])

  def redirect_signed_in_person_to_account_form
    redirect_to new_account_path if authenticated?
  end

  def rate_limit_exceeded
    redirect_to new_signup_path, alert: t("sessions.rate_limited"), status: :see_other
  end
end
