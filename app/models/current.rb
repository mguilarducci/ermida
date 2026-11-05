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

  # Nothing sets the account yet; the condominium in the URL will, and then the user follows.
  def account=(account)
    super
    self.user = identity&.user_in(account)
  end
end
