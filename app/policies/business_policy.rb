class BusinessPolicy < ApplicationPolicy
  # Anyone may manage businesses until the app has login.
  def index? = true

  def create? = true

  def manage? = true
end
