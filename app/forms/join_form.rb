# Confirming a join: saves the person's name when Ermida has none, and makes them a member of the account.
class JoinForm < ApplicationForm
  attribute :person_name, :string

  attr_accessor :account, :identity
  attr_reader :user

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
    @user = account.join(identity)
  end

  def copy_errors_from(record)
    attribute = record.is_a?(Identity) ? :person_name : :base
    record.errors.each { |error| errors.add(attribute, error.type, **error.options) }
  end
end
