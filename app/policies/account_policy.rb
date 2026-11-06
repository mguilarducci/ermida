class AccountPolicy < ApplicationPolicy
  def index? = true

  def create? = true

  # Only the account's active users get in.
  def show? = user.present? && user.active? && user.account_id == record.id

  # Only owners and admins see the join link.
  def share? = show? && user.administrator?

  # Joining is for people who are not yet active users of the account; those go straight in.
  def join? = !show?
end
