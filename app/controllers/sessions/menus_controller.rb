# The accounts a signed-in person belongs to. With exactly one, the person goes straight into it.
class Sessions::MenusController < ApplicationController
  disallow_account_scope
  verify_authorized

  def show
    authorize! Account, to: :index?
    @accounts = Current.identity.accounts.load

    if @accounts.one?
      redirect_to root_path(script_name: account_script_name(@accounts.first))
    end
  end
end
