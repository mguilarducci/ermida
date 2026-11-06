# The share page: the account's join link, for its owners and admins.
class SharesController < ApplicationController
  verify_authorized

  def show
    @account = Current.account
    authorize! @account, to: :share?
  end
end
