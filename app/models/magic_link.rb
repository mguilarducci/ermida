class MagicLink < ApplicationRecord
  EXPIRATION_TIME = 15.minutes

  db_belongs_to :identity

  enum :purpose, %w[sign_in sign_up].index_by(&:itself), prefix: :for, default: :sign_in, validate: true

  scope :active, -> { where(expires_at: Time.current..) }
  scope :stale, -> { where(expires_at: ...Time.current) }

  before_validation :generate_code, :set_expiration, on: :create

  class << self
    def consume(code)
      if (sanitized = Code.sanitize(code))
        active.find_by(code: sanitized)&.consume
      end
    end

    def cleanup
      stale.delete_all
    end
  end

  def consume
    destroy!
  end

  private

  def generate_code
    self.code ||= loop do
      candidate = Code.generate
      break candidate unless self.class.exists?(code: candidate)
    end
  end

  def set_expiration
    self.expires_at ||= EXPIRATION_TIME.from_now
  end
end
