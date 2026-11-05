# Base class for application policies
class ApplicationPolicy < ActionPolicy::Base
  # There is no login yet, so policies run with a nil user. Rules that need one must check for it.
  #
  # Read more about authorization context: https://actionpolicy.evilmartians.io/#/authorization_context
  authorize :user, allow_nil: true

  private

  # Define shared methods useful for most policies.
  # For example:
  #
  #  def owner?
  #    record.user_id == user.id
  #  end
end
