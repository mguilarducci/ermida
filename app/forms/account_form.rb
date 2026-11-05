# The form that creates an Account: its name, and the person's own name when they have none yet, as happens right
# after signing up.
class AccountForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :name, :string
  attribute :person_name, :string

  attr_accessor :identity
  attr_reader :account

  validates :name, presence: true
  validates :person_name, presence: true, if: :person_name_needed?

  def self.model_name = ActiveModel::Name.new(self, nil, "Account")

  def person_name_needed? = identity.name.blank?

  def save
    if valid?
      create_account
    else
      false
    end
  end

  private

  def create_account
    ActiveRecord::Base.transaction do
      identity.update!(name: person_name) if person_name_needed?
      @account = Account.create_with_owner(name:, owner: identity)
    end
    true
  rescue ActiveRecord::RecordInvalid => error
    identity.restore_attributes
    copy_errors_from(error.record)
    false
  end

  def copy_errors_from(record)
    attribute = record.is_a?(Identity) ? :person_name : :name
    record.errors.each { |error| errors.add(attribute, error.type, **error.options) }
  end
end
