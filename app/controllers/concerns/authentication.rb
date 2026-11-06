module Authentication
  extend ActiveSupport::Concern

  included do
    before_action :require_authentication
    helper_method :authenticated?
  end

  class_methods do
    def allow_unauthenticated_access(**options)
      skip_before_action :require_authentication, **options
    end

    def require_unauthenticated_access(**options)
      allow_unauthenticated_access(**options)
      before_action :redirect_signed_in_person, **options
    end
  end

  private

  def authenticated?
    resume_session
  end

  def require_authentication
    resume_session || request_authentication
  end

  def resume_session
    Current.session ||= find_session_by_cookie
  end

  def find_session_by_cookie
    Session.find_by(id: cookies.signed[:session_id]) if cookies.signed[:session_id]
  end

  # The stored path is where signing in returns to. It is always a path inside the app. It lives in the
  # cookie session, which overflows past 4 KB, so a long URL is not remembered rather than turned into a 500.
  def request_authentication
    if request.get? && request.fullpath.bytesize <= 1.kilobyte
      return_after_authenticating_to request.fullpath
    end
    redirect_to new_session_path(script_name: nil)
  end

  # Where signing in returns to, for a page that sends the person through the code page itself. Only paths the app
  # built go here, never one taken from the request.
  def return_after_authenticating_to(path)
    session[:return_to_after_authenticating] = path
  end

  def redirect_signed_in_person
    redirect_to root_path(script_name: nil) if authenticated?
  end

  def after_authentication_url
    session.delete(:return_to_after_authenticating) || root_path(script_name: nil)
  end

  def start_new_session_for(identity)
    identity.sessions.create!(user_agent: request.user_agent, ip_address: request.remote_ip).tap do |session|
      Current.session = session
      cookies.signed.permanent[:session_id] = {value: session.id, httponly: true, same_site: :lax}
    end
  end

  def terminate_session
    Current.session.destroy
    cookies.delete(:session_id)
  end
end
