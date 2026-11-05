module Authentication::ViaMagicLink
  extend ActiveSupport::Concern

  # Longer than a code lives, so an expired code still reaches the code page and is refused there.
  PENDING_AUTHENTICATION_LIFETIME = 1.hour

  included do
    after_action :ensure_magic_link_code_stays_in_development
  end

  private

  def redirect_to_session_magic_link(magic_link)
    remember_pending_authentication(magic_link.identity.email_address)
    flash[:magic_link_code] = magic_link.code if Rails.env.development?
    redirect_to session_magic_link_path, status: :see_other
  end

  def redirect_to_fake_session_magic_link(email_address)
    remember_pending_authentication(email_address)
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

  def ensure_magic_link_code_stays_in_development
    if flash[:magic_link_code] && !Rails.env.development?
      raise "The sign-in code reached the flash outside development"
    end
  end
end
