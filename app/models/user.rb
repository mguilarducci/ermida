# An identity's place in one condominium. System users, and users whose person left, have no identity.
class User < ApplicationRecord
  db_belongs_to :account
  belongs_to :identity, optional: true

  enum :role, %w[member provider admin owner system].index_by(&:itself), default: :member, validate: true

  validates_db_uniqueness_of :identity_id, scope: :account_id, index_name: :index_users_on_account_id_and_identity_id

  scope :active, -> { where(active: true) }

  # Leaving is one-way: a person who comes back gets a new user.
  def deactivate
    update!(active: false, identity: nil)
  end
end
