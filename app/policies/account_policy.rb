class AccountPolicy < ApplicationPolicy
  def index? = true

  def create? = true

  # Only the account's active users get in.
  def show? = user.present? && user.active? && user.account_id == record.id
end
