class Identity < ApplicationRecord
  has_many :users, dependent: :restrict_with_exception
  has_many :sessions, dependent: :destroy
  has_many :magic_links, dependent: :destroy

  normalizes :email_address, with: ->(email_address) { email_address.strip.downcase }

  validates :email_address, presence: true, format: {with: URI::MailTo::EMAIL_REGEXP}
  validates_db_uniqueness_of :email_address
  validates :name, length: {maximum: 100}

  # Two sign-ups racing on one new address both miss the lookup; the one whose insert loses gets the address marked
  # taken (database_validations turns the unique index error into that), and finds the winner's identity instead.
  def self.find_or_create_by_email_address(email_address)
    identity = find_or_create_by(email_address:)

    if identity.errors.of_kind?(:email_address, :taken)
      find_by!(email_address:)
    else
      identity
    end
  end

  def create_magic_link(purpose:)
    if magic_links.recent.count < MagicLink::ISSUE_LIMIT
      magic_links.create!(purpose:)
    end
  end

  def accounts
    Account.where(id: users.active.select(:account_id)).order(:name)
  end

  # Only an active user counts, so a former resident stays out even if a user lost its active flag some other way.
  def user_in(account)
    if account
      users.active.find_by(account:)
    end
  end
end
