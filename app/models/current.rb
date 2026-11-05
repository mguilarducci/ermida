# Request context. Only the Authentication concern sets it, and only controllers read it; models get
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

  def account=(account)
    super
    self.user = identity&.user_in(account)
  end
end
