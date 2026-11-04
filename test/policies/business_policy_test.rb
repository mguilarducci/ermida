require "test_helper"

class BusinessPolicyTest < ActiveSupport::TestCase
  test "allows every CRUD rule without a signed-in user" do
    policy = BusinessPolicy.new(build(:business), user: nil)

    %i[index? show? new? create? edit? update? destroy?].each do |rule|
      assert policy.apply(rule), "expected #{rule} to be allowed"
    end
  end
end
