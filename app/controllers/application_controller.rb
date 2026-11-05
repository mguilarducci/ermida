class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  private

  # Action Policy reads the user from here. Login will replace this; until then nobody is signed in.
  def current_user = nil
end
