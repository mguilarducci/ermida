class BusinessPolicy < ApplicationPolicy
  # Anyone signed in may manage businesses until roles decide who may.
  def index? = true

  def create? = true

  def manage? = true
end
