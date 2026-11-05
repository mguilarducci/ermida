# A sign-in code: six characters from an alphabet without the letters people confuse with digits.
class MagicLink::Code < Data.define(:value)
  LENGTH = 6
  ALPHABET = (("0".."9").to_a + ("A".."Z").to_a - %w[I L O U]).freeze
  LOOK_ALIKES = {"O" => "0", "I" => "1", "L" => "1"}.freeze

  class << self
    def generate = new(SecureRandom.alphanumeric(LENGTH, chars: ALPHABET))

    # Reads what a person typed: any case, with spaces or dashes, and O, I or L for 0, 1 or 1.
    # Nil when nothing in it can be part of a code.
    def parse(input)
      characters = input.to_s.upcase.gsub(Regexp.union(LOOK_ALIKES.keys), LOOK_ALIKES).delete("^#{ALPHABET.join}")

      if characters.present?
        new(characters)
      end
    end
  end

  def to_s = value
end
