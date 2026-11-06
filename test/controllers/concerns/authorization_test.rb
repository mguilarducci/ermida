require "test_helper"

class AuthorizationTest < ActionDispatch::IntegrationTest
  class SignedOutPageController < ApplicationController
    allow_unauthenticated_access

    def show = head(:ok)
  end

  class NonMemberPageController < ApplicationController
    allow_unauthenticated_access
    allow_unauthorized_access

    def show = head(:ok)
  end

  setup do
    @account = create(:account, name: "Edifício Aurora")
    @identity = create(:identity)
  end

  test "a page open to signed-out visitors lets them in" do
    with_probe_routes { get "/accounts/edificio-aurora/signed_out" }

    assert_response :success
  end

  test "a page open to signed-out visitors still sends a signed-in non-member to the menu" do
    create(:user, identity: @identity)

    with_probe_routes do
      sign_in_as(@identity)
      get "/accounts/edificio-aurora/signed_out"
    end

    assert_redirected_to "/session/menu"
  end

  test "a page that also allows unauthorized access lets a signed-in non-member in" do
    create(:user, identity: @identity)

    with_probe_routes do
      sign_in_as(@identity)
      get "/accounts/edificio-aurora/non_member"
    end

    assert_response :success
  end

  private

  # with_routing replaces the whole route set, so it also draws the routes the concerns redirect to. It also starts
  # a new integration session, so tests sign in inside the block.
  def with_probe_routes
    with_routing do |routes|
      routes.draw do
        get "signed_out", to: "authorization_test/signed_out_page#show"
        get "non_member", to: "authorization_test/non_member_page#show"
        resource :session, only: :new do
          scope module: :sessions do
            resource :menu, only: :show
          end
        end
        root "landings#show"
      end
      yield
    end
  end
end
