# Inside an account, only its active users get in (AccountPolicy#show?). Anyone else goes back to the menu.
# Runs after Authentication and reads its `authenticated?`; Authentication never refers back to this concern.
# A page that lets signed-in people who are not users of the account in (a join link) declares
# `allow_unauthorized_access` and authorizes the visitor itself. A user refused one page of their account goes back
# to the account's page.
module Authorization
  extend ActiveSupport::Concern

  included do
    before_action :ensure_account_access, if: :account_access?
    rescue_from ActionPolicy::Unauthorized, with: :deny_access
  end

  class_methods do
    def allow_unauthorized_access(**options)
      skip_before_action :ensure_account_access, **options
    end
  end

  private

  def account_access? = Current.account.present? && authenticated?

  def ensure_account_access
    if !allowed_to?(:show?, Current.account)
      redirect_to session_menu_path(script_name: nil)
    end
  end

  # Outside an account, root_path leads to the menu.
  def deny_access
    redirect_to root_path, alert: t("authorization.denied"), status: :see_other
  end
end
