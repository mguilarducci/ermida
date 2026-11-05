# The page an account opens on.
class LandingsController < ApplicationController
  verify_authorized

  def show
    @account = Current.account
    authorize! @account
  end
end
