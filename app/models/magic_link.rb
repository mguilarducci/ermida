class MagicLink < ApplicationRecord
  EXPIRATION_TIME = 15.minutes
  # Caps how many codes an attacker can make live for one person, whatever number of addresses they use.
  ISSUE_LIMIT = 5
  ISSUE_WINDOW = 15.minutes

  db_belongs_to :identity

  enum :purpose, %w[sign_in sign_up].index_by(&:itself), prefix: :for, default: :sign_in, validate: true

  scope :active, -> { where(expires_at: Time.current..) }
  scope :stale, -> { where(expires_at: ...Time.current) }
  scope :recent, -> { where(created_at: ISSUE_WINDOW.ago..) }

  before_validation :generate_code, :set_expiration, on: :create

  class << self
    def consume(code)
      if (parsed = Code.parse(code))
        active.find_by(code: parsed.value)&.consume
      end
    end

    def cleanup
      stale.delete_all
    end
  end

  def consume
    if self.class.where(id:).delete_all == 1
      self
    end
  end

  private

  def generate_code
    self.code ||= loop do
      candidate = Code.generate.value
      break candidate unless self.class.exists?(code: candidate)
    end
  end

  def set_expiration
    self.expires_at ||= EXPIRATION_TIME.from_now
  end
end
