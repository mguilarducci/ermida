class User < ApplicationRecord
  # Inside an account's pages, users of other accounts are out of reach.
  acts_as_tenant :account
  belongs_to :identity, optional: true

  enum :role, %w[member provider admin owner system].index_by(&:itself), default: :member, validate: true

  validates_db_uniqueness_of :identity_id, scope: :account_id, index_name: :index_users_on_account_id_and_identity_id

  scope :active, -> { where(active: true) }

  # Leaving is one-way: a person who comes back gets a new user.
  def deactivate
    update!(active: false, identity: nil)
  end
end
