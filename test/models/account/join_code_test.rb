require "test_helper"

class Account::JoinCodeTest < ActiveSupport::TestCase
  test "a generated code is three groups of four base58 characters joined by dashes" do
    codes = Array.new(200) { Account::JoinCode.generate.value }

    assert(codes.all? { |code| code.match?(/\A[1-9A-HJ-NP-Za-km-z]{4}(-[1-9A-HJ-NP-Za-km-z]{4}){2}\z/) })
  end

  test "two generated codes differ" do
    assert_not_equal Account::JoinCode.generate, Account::JoinCode.generate
  end

  test "a code matches only its own value" do
    code = Account::JoinCode.new("abcd-efgh-ijkm")

    assert code.matches?("abcd-efgh-ijkm")
    assert_not code.matches?("abcd-efgh-ijkn")
    assert_not code.matches?("")
    assert_not code.matches?(nil)
  end

  test "a code reads as its value" do
    assert_equal "abcd-efgh-ijkm", Account::JoinCode.new("abcd-efgh-ijkm").to_s
  end
end
