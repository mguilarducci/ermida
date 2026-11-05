# Inside an account, only its active users get in (AccountPolicy#show?). Anyone else goes back to the menu.
module Authorization
  extend ActiveSupport::Concern

  included do
    before_action :ensure_account_access, if: :account_access?
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
end
