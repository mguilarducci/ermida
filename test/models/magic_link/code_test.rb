require "test_helper"

class MagicLink::CodeTest < ActiveSupport::TestCase
  test "generated codes never contain letters people confuse with digits" do
    codes = Array.new(200) { MagicLink::Code.generate }

    assert(codes.all? { |code| code.length == 6 })
    assert_empty codes.join.chars.uniq - MagicLink::Code::ALPHABET
    assert_no_match(/[ILOU]/, codes.join)
  end

  test "sanitizing upcases, maps look-alikes and drops anything outside the alphabet" do
    assert_equal "1A0B1C", MagicLink::Code.sanitize("i-a o b l c")
    assert_nil MagicLink::Code.sanitize(nil)
  end
end
