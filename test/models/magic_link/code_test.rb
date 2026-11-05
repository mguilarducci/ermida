require "test_helper"

class MagicLink::CodeTest < ActiveSupport::TestCase
  test "generated codes never contain letters people confuse with digits" do
    codes = Array.new(200) { MagicLink::Code.generate.value }

    assert(codes.all? { |code| code.length == 6 })
    assert_empty codes.join.chars.uniq - MagicLink::Code::ALPHABET
    assert_no_match(/[ILOU]/, codes.join)
  end

  test "parsing upcases, maps look-alikes and drops anything outside the alphabet" do
    assert_equal MagicLink::Code.new("1A0B1C"), MagicLink::Code.parse("i-a o b l c")
  end

  test "parsing gives nothing when no character can be part of a code" do
    assert_nil MagicLink::Code.parse(nil)
    assert_nil MagicLink::Code.parse(" - ")
  end

  test "a code reads as its characters" do
    assert_equal "1A0B1C", MagicLink::Code.new("1A0B1C").to_s
  end
end
