class ApplicationController < ActionController::Base
  include Authentication

  # Only allow modern browsers supporting webp images, web push, badges, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  private

  # Action Policy reads the user from here. It stays nil until something sets the current condominium.
  def current_user = Current.user
end
