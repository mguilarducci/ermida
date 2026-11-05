class AccountPolicy < ApplicationPolicy
  def index? = true

  def create? = true
end
