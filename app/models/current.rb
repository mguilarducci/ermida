# Request context. Only the AccountScoping and Authentication concerns set it, and only controllers read it; models get
# what they need as arguments.
class Current < ActiveSupport::CurrentAttributes
  attribute :session, :identity, :user, :account

  def session=(session)
    super
    self.identity = session&.identity
  end

  def identity=(identity)
    super
    self.user = identity&.user_in(account)
  end

  # The account also scopes the models that belong to one (acts_as_tenant).
  def account=(account)
    super
    ActsAsTenant.current_tenant = account
    self.user = identity&.user_in(account)
  end
end
