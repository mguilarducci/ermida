class AccountForm < ApplicationForm
  attribute :name, :string
  attribute :person_name, :string

  attr_accessor :identity
  attr_reader :account

  validates :name, presence: true
  validates :person_name, presence: true, if: :person_name_needed?

  def person_name_needed? = identity.name.blank?

  def save
    super
  rescue ActiveRecord::RecordInvalid => error
    identity.restore_attributes
    copy_errors_from(error.record)
    false
  end

  private

  def submit!
    identity.update!(name: person_name) if person_name_needed?
    @account = Account.create_with_owner(name:, owner: identity)
  end

  def copy_errors_from(record)
    attribute = record.is_a?(Identity) ? :person_name : :name
    record.errors.each { |error| errors.add(attribute, error.type, **error.options) }
  end
end
