class SessionsController < ApplicationController
  def new
  end

  def destroy
    terminate_session
    redirect_to new_session_path, status: :see_other
  end
end
