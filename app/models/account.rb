# A condominium: the space where residents, service providers and the people who run it act together.
class Account < ApplicationRecord
  extend FriendlyId

  # Route words under /accounts/. Accounts live under /accounts/<slug>/ (config/initializers/account_slug.rb),
  # so a slug equal to one of these would hide that page.
  RESERVED_SLUGS = %w[new edit].freeze

  # The slug is generated once from the name and never changes, so links keep working after a rename.
  # Conflicts get the next sequential suffix, and reserved words count as taken.
  friendly_id :name, use: %i[slugged sequentially_slugged reserved],
    reserved_words: RESERVED_SLUGS, treat_reserved_as_conflict: true

  has_many :users

  # The cap also keeps the slug well under the size Postgres accepts in its unique index.
  validates :name, presence: true, length: {maximum: 100}
  validate :name_must_produce_a_slug
  validates_db_uniqueness_of :slug
  validates_db_uniqueness_of :join_code

  # Model inspection does not print the join code, which lets anyone who has it join.
  self.filter_attributes += %i[join_code]

  before_validation :generate_join_code, on: :create

  def self.create_with_owner(name:, owner:)
    transaction do
      create!(name:).tap do |account|
        account.users.create!(role: :system)
        account.users.create!(role: :owner, identity: owner, verified_at: Time.current)
      end
    end
  end

  # A person joins as a member, verified by the code they typed. One who is already an active user stays as they
  # are. One whose user was deactivated gets a new user, since leaving is one-way. A join that loses a race with
  # another join for the same person gets the user that one created.
  def join(identity)
    raise ArgumentError, "joining needs a person" if identity.nil?

    users.active.find_by(identity:) || users.create!(identity:, role: :member, verified_at: Time.current)
  rescue ActiveRecord::RecordInvalid => error
    raise unless error.record.errors.of_kind?(:identity_id, :taken)

    users.active.find_by!(identity:)
  end

  def join_code?(input) = Account::JoinCode.new(join_code).matches?(input)

  private

  def name_must_produce_a_slug
    if name.present? && normalize_friendly_id(name).blank?
      errors.add(:name, :invalid)
    end
  end

  def generate_join_code
    self.join_code ||= Account::JoinCode.generate.to_s
  end
end
