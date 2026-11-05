class AccountPolicy < ApplicationPolicy
  # Anyone signed in may list their accounts and create one; the listing is already limited to their own.
  def index? = true

  def create? = true
end
