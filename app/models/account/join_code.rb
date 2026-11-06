# A join link's secret: 12 base58 characters in groups of four, as in Fizzy (about 10^21 values), so a link that
# never changes cannot be guessed.
class Account::JoinCode < Data.define(:value)
  LENGTH = 12

  def self.generate = new(SecureRandom.base58(LENGTH).scan(/.{4}/).join("-"))

  # Constant time, so response timing does not tell a guesser how much of a code is right.
  def matches?(input) = ActiveSupport::SecurityUtils.secure_compare(value, input.to_s)

  def to_s = value
end
