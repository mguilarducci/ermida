# Pages behind a join link (/accounts/<slug>/join/<code>). They let in people who are not users of the account, so
# each checks, on every request, that the code in the URL is the account's: the slug alone never lets anyone join.
module JoinLinkAccess
  extend ActiveSupport::Concern

  included do
    allow_unauthorized_access
    # A page that skips both the session and the member check loads no session, and Action Policy keeps the first
    # user it reads, so the session is resumed before any check.
    before_action :resume_session
    before_action :require_join_code
    before_action :enter_account_as_user
  end

  private

  def require_join_code
    raise ActiveRecord::RecordNotFound unless Current.account.join_code?(params[:code])
  end

  # An active user of the account goes straight in.
  def enter_account_as_user
    redirect_to root_path if allowed_to?(:show?, Current.account)
  end

  # The email typed on this device for this link. The confirmation opens only for it, so neither opening the
  # confirmation's URL nor a return path left on a shared device joins anyone without typing their email.
  def remember_pending_join(email_address)
    session[:pending_join] = {"code" => params[:code], "email_address" => email_address}
  end

  def pending_join_for?(identity)
    pending = session[:pending_join] || {}
    pending["code"] == params[:code] && pending["email_address"] == identity&.email_address
  end

  def forget_pending_join
    session.delete(:pending_join)
  end
end
