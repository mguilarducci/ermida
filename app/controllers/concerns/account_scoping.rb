# Every page belongs to the account in its URL (/accounts/edificio-aurora/...), which becomes Current.account.
# Pages that belong to no account, such as signing in or the account menu, declare `disallow_account_scope`.
# Included before Authentication, so the session that follows finds the person's user in the account.
module AccountScoping
  extend ActiveSupport::Concern

  included do
    before_action :set_current_account
    before_action :require_account
    helper_method :account_script_name
  end

  class_methods do
    # Under an account's slug, these pages send the person to the home page outside it.
    def disallow_account_scope(**options)
      skip_before_action :require_account, **options
      before_action :redirect_tenanted_request, **options
    end
  end

  private

  # A slug that matches no account is a page that does not exist.
  def set_current_account
    if (slug = request.env[AccountSlug::ENV_KEY])
      Current.account = Account.find_by!(slug:)
    end
  end

  def require_account
    if Current.account.nil?
      redirect_to session_menu_path(script_name: nil)
    end
  end

  def redirect_tenanted_request
    if Current.account
      redirect_to root_path(script_name: nil)
    end
  end

  # url helpers take it to link into an account: `root_path(script_name: account_script_name(account))`.
  def account_script_name(account) = "#{AccountSlug::PATH}/#{account.slug}"
end
