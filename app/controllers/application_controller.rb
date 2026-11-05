class ApplicationController < ActionController::Base
  include AccountScoping
  include Authentication
  include Authorization

  # Only allow modern browsers supporting webp images, web push, badges, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  private

  # Action Policy reads the user from here: the person's active user in the account of the URL, nil outside one.
  def current_user = Current.user
end
