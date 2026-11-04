# Flash messages as daisyUI alerts: a notice reads as a status, an alert as an error.
class Flash::Component < ApplicationViewComponent
  def initialize(notice: nil, alert: nil)
    @notice = notice
    @alert = alert
  end

  def render? = notice.present? || alert.present?

  private

  attr_reader :notice, :alert
end
