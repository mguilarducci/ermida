class Identity < ApplicationRecord
  has_many :users, dependent: :restrict_with_exception
  has_many :sessions, dependent: :destroy

  normalizes :email_address, with: ->(email_address) { email_address.strip.downcase }

  validates :email_address, presence: true, format: {with: URI::MailTo::EMAIL_REGEXP}
  validates_db_uniqueness_of :email_address
  validates :name, presence: true, length: {maximum: 100}

  # Only an active user counts, so a former resident stays out even if a user lost its active flag some other way.
  def user_in(account)
    if account
      users.active.find_by(account:)
    end
  end
end
