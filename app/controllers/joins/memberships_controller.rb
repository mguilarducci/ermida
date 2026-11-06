# A join link's confirmation. It needs a session, which the code page started or the person already had, and the
# email typed on the join page on this device for this link.
class Joins::MembershipsController < ApplicationController
  include JoinLinkAccess

  before_action :require_pending_join
  verify_authorized

  def new
    @account = Current.account
    authorize! @account, to: :join?
    @join = JoinForm.new(account: @account, identity: Current.identity)
  end

  def create
    @account = Current.account
    authorize! @account, to: :join?
    @join = JoinForm.new(join_params.merge(account: @account, identity: Current.identity))

    if @join.save
      forget_pending_join
      redirect_to root_path, status: :see_other
    else
      render :new, status: :unprocessable_content
    end
  end

  private

  def require_pending_join
    redirect_to join_path(params[:code]) unless pending_join_for?(Current.identity)
  end

  # A person who already has a name submits no fields.
  def join_params = params.fetch(:join, {}).permit(:person_name)
end
