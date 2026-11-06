require "test_helper"

class SharesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @account = create(:account, name: "Edifício Aurora")
    @identity = create(:identity)
  end

  test "an owner sees the account's join link" do
    create(:user, identity: @identity, account: @account, role: :owner)
    sign_in_as(@identity)

    get "/accounts/edificio-aurora/share"

    assert_response :success
    assert_select "input[value=?]", "http://www.example.com/accounts/edificio-aurora/join/#{@account.join_code}"
  end

  test "a member is sent back to the account's page without seeing the join link" do
    create(:user, identity: @identity, account: @account, role: :member)
    sign_in_as(@identity)

    get "/accounts/edificio-aurora/share"

    assert_redirected_to "/accounts/edificio-aurora/"
    assert_equal I18n.t("authorization.denied"), flash[:alert]
    assert_not_includes response.body, @account.join_code
  end
end
