require "test_helper"
require "action_policy/test_helper"

class BusinessesControllerTest < ActionDispatch::IntegrationTest
  include ActionPolicy::TestHelper

  setup { sign_in_as(create(:identity)) }

  test "businesses under an account's slug go to the home page" do
    identity = create(:identity)
    account = create(:user, identity:).account
    sign_in_as(identity)

    get "/accounts/#{account.slug}/businesses"

    assert_redirected_to "/"
  end

  test "index lists businesses alphabetically, each linking to its slug" do
    create(:business, name: "Bravo")
    create(:business, name: "Alpha")

    get businesses_path

    assert_response :success
    assert_select "table.table tbody tr", count: 2
    assert_select "table.table tbody tr:nth-child(1) a[href=?]", "/businesses/alpha", text: "Alpha"
    assert_select "table.table tbody tr:nth-child(2) a[href=?]", "/businesses/bravo", text: "Bravo"
    assert_select "a.btn[href=?]", new_business_path
  end

  test "the new form opens even when a business holds a suffixed route word" do
    create(:business, name: "New")

    get "/businesses/new"

    assert_response :success
    assert_select "form[action=?]", businesses_path
  end

  test "show finds a business by slug" do
    create(:business, name: "Padaria do João", description: "Fresh bread daily.")

    get "/businesses/padaria-do-joao"

    assert_response :success
    assert_select "h1", text: "Padaria do João"
    assert_select "p", text: "Fresh bread daily."
    assert_select "form[action=?] button.btn-error", "/businesses/padaria-do-joao"
  end

  test "an unknown slug responds not found" do
    get "/businesses/nowhere"

    assert_response :not_found
  end

  test "a numeric id does not open a business page" do
    business = create(:business, name: "Padaria do João")

    get "/businesses/#{business.id}"

    assert_response :not_found
  end

  test "create redirects to the new business with a notice" do
    post businesses_path, params: {business: {name: "Padaria do João", description: "Fresh bread daily."}}

    assert_redirected_to "/businesses/padaria-do-joao"
    assert_equal "Business created.", flash[:notice]
  end

  test "create with a blank name re-renders the form with the description kept" do
    assert_no_difference -> { Business.count } do
      post businesses_path, params: {business: {name: "", description: "Fresh bread daily."}}
    end

    assert_response :unprocessable_content
    assert_select "input#business_name[aria-invalid=true]"
    assert_select "textarea#business_description", text: "Fresh bread daily."
  end

  test "create ignores a submitted slug" do
    post businesses_path, params: {business: {name: "Padaria do João", slug: "custom"}}

    assert_equal "padaria-do-joao", Business.last.slug
  end

  test "renaming keeps the URL and sets a notice" do
    business = create(:business, name: "Padaria do João")

    patch business_path(business), params: {business: {name: "Café Central"}}

    assert_redirected_to "/businesses/padaria-do-joao"
    assert_equal "Business updated.", flash[:notice]
    assert_equal "Café Central", business.reload.name
  end

  test "update with a blank name responds unprocessable" do
    business = create(:business)

    patch business_path(business), params: {business: {name: ""}}

    assert_response :unprocessable_content
  end

  test "destroy removes the business and returns to the index" do
    business = create(:business)

    delete business_path(business)

    assert_response :see_other
    assert_redirected_to businesses_path
    assert_equal "Business deleted.", flash[:notice]
    assert_not Business.exists?(business.id)
  end

  test "every action is authorized through the business policy" do
    business = create(:business)

    assert_authorized_to(:index?, Business, with: BusinessPolicy) { get businesses_path }
    # Action Policy aliases new? to create?
    assert_authorized_to(:create?, Business, with: BusinessPolicy) { get new_business_path }
    assert_authorized_to(:create?, Business, with: BusinessPolicy) do
      post businesses_path, params: {business: {name: "Alpha"}}
    end
    # show?, edit?, update? and destroy? fall back to manage?
    assert_authorized_to(:manage?, business, with: BusinessPolicy) { get business_path(business) }
    assert_authorized_to(:manage?, business, with: BusinessPolicy) { get edit_business_path(business) }
    assert_authorized_to(:manage?, business, with: BusinessPolicy) do
      patch business_path(business), params: {business: {name: "Bravo"}}
    end
    assert_authorized_to(:manage?, business, with: BusinessPolicy) { delete business_path(business) }
  end
end
