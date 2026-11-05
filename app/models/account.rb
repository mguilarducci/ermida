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

  def self.create_with_owner(name:, owner:)
    transaction do
      create!(name:).tap do |account|
        account.users.create!(role: :system)
        account.users.create!(role: :owner, identity: owner, verified_at: Time.current)
      end
    end
  end

  private

  def name_must_produce_a_slug
    if name.present? && normalize_friendly_id(name).blank?
      errors.add(:name, :invalid)
    end
  end
end
