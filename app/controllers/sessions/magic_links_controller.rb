class Sessions::MagicLinksController < ApplicationController
  include Authentication::ViaMagicLink

  require_unauthenticated_access
  rate_limit to: 10, within: 15.minutes, only: :create, with: :rate_limit_exceeded
  rate_limit to: 10, within: 15.minutes, only: :create, with: :rate_limit_exceeded, name: "per-email",
    by: -> { email_address_pending_authentication.to_s }
  before_action :require_pending_authentication

  def show
    @email_address = email_address_pending_authentication
  end

  def create
    magic_link = MagicLink.consume(params[:code])

    if magic_link.nil?
      redirect_to session_magic_link_path, alert: t(".invalid_code"), status: :see_other
    elsif pending_authentication_matches?(magic_link)
      clear_pending_authentication
      start_new_session_for(magic_link.identity)
      redirect_to after_sign_in_url(magic_link), status: :see_other
    else
      clear_pending_authentication
      redirect_to new_session_path, alert: t(".mismatch"), status: :see_other
    end
  end

  private

  def require_pending_authentication
    if email_address_pending_authentication.nil?
      redirect_to new_session_path, alert: t("sessions.magic_links.enter_email")
    end
  end

  def pending_authentication_matches?(magic_link)
    ActiveSupport::SecurityUtils.secure_compare(email_address_pending_authentication, magic_link.identity.email_address)
  end

  def after_sign_in_url(magic_link)
    if magic_link.for_sign_up?
      new_account_path
    else
      after_authentication_url
    end
  end

  def rate_limit_exceeded
    redirect_to session_magic_link_path, alert: t("sessions.rate_limited"), status: :see_other
  end
end
