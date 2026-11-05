class Business < ApplicationRecord
  extend FriendlyId

  # The slug is generated once from the name and never changes, so links keep working after a rename.
  # Conflicts get the next sequential suffix, and route words count as taken.
  friendly_id :name, use: %i[slugged sequentially_slugged reserved],
    reserved_words: %w[new edit], treat_reserved_as_conflict: true

  # The cap also keeps the slug well under the size Postgres accepts in its unique index.
  validates :name, presence: true, length: {maximum: 100}
  validate :name_must_produce_a_slug

  scope :alphabetical, -> { order(:name) }

  private

  def name_must_produce_a_slug
    if name.present? && normalize_friendly_id(name).blank?
      errors.add(:name, :invalid)
    end
  end
end
