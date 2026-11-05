class AccountsController < ApplicationController
  verify_authorized

  def index
    authorize!
    @accounts = Current.identity.accounts.load
  end

  def new
    authorize!
    @form = AccountForm.new(identity: Current.identity)
  end

  def create
    authorize!
    @form = AccountForm.new(account_params.merge(identity: Current.identity))

    if @form.save
      redirect_to root_path, notice: t(".created")
    else
      render :new, status: :unprocessable_content
    end
  end

  private

  def account_params = params.expect(account: %i[name person_name])
end
