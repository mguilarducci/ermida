module Authentication::ViaMagicLink
  extend ActiveSupport::Concern

  # Longer than a code lives, so an expired code still reaches the code page and is refused there.
  PENDING_AUTHENTICATION_LIFETIME = 1.hour

  included do
    after_action :ensure_magic_link_code_stays_off_the_page
  end

  private

  # Without a magic link (an unknown email, or one past its code limit) the person sees the same page.
  def redirect_to_session_magic_link(email_address, magic_link)
    remember_pending_authentication(email_address)
    flash[:magic_link_code] = magic_link.code if magic_link && AuthenticationConfig.show_code_on_page?
    redirect_to session_magic_link_path, status: :see_other
  end

  def remember_pending_authentication(email_address)
    cookies.signed[:pending_authentication_token] = {
      value: email_address,
      expires: PENDING_AUTHENTICATION_LIFETIME.from_now,
      httponly: true,
      same_site: :lax
    }
  end

  def email_address_pending_authentication
    cookies.signed[:pending_authentication_token]
  end

  def clear_pending_authentication
    cookies.delete(:pending_authentication_token)
  end

  def ensure_magic_link_code_stays_off_the_page
    if flash[:magic_link_code] && !AuthenticationConfig.show_code_on_page?
      raise "The sign-in code reached the flash while the code page must not show it"
    end
  end
end
