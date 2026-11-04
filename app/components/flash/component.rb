class Flash::Component < ApplicationViewComponent
  def initialize(notice: nil, alert: nil)
    @notice = notice
    @alert = alert
  end

  def render? = notice.present? || alert.present?

  private

  attr_reader :notice, :alert
end
