# Codes use Crockford's base32 alphabet, which leaves out I, L, O and U, so a person who types a letter that looks
# like a digit still gets the digit.
module MagicLink::Code
  LENGTH = 6
  ALPHABET = (("0".."9").to_a + ("A".."Z").to_a - %w[I L O U]).freeze
  LOOK_ALIKES = {"O" => "0", "I" => "1", "L" => "1"}.freeze

  class << self
    def generate
      SecureRandom.alphanumeric(LENGTH, chars: ALPHABET)
    end

    def sanitize(code)
      if code
        code.to_s.upcase.gsub(/[OIL]/, LOOK_ALIKES).delete("^#{ALPHABET.join}").presence
      end
    end
  end
end
