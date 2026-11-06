# A join link's page: names the account and always asks for an email, so typing it settles who joins, even on a
# shared device. Opening it creates nothing, so a chat app building a preview of the link joins no one.
class JoinsController < ApplicationController
  include Authentication::ViaMagicLink
  include JoinLinkAccess

  allow_unauthenticated_access
  rate_limit to: 10, within: 3.minutes, only: :create, with: :rate_limit_exceeded
  verify_authorized

  def show
    @account = Current.account
    authorize! @account, to: :join?
    @join_request = JoinRequestForm.new
  end

  def create
    @account = Current.account
    authorize! @account, to: :join?
    @join_request = JoinRequestForm.new(join_request_params)

    if @join_request.from?(Current.identity)
      remember_pending_join(@join_request.email_address)
      redirect_to new_join_membership_path(params[:code]), status: :see_other
    elsif @join_request.save
      send_code
    else
      render :show, status: :unprocessable_content
    end
  end

  private

  def join_request_params = params.expect(join_request: [:email_address])

  # Another person's email ends the session on this device before the code goes out. The email was saved first, so
  # a typo never signs anyone out.
  def send_code
    terminate_session if authenticated?
    remember_pending_join(@join_request.email_address)
    return_after_authenticating_to new_join_membership_path(params[:code])
    redirect_to_session_magic_link(@join_request.email_address, @join_request.magic_link)
  end

  def rate_limit_exceeded
    redirect_to join_path(params[:code]), alert: t("sessions.rate_limited"), status: :see_other
  end
end
