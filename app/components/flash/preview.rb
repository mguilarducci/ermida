class Flash::Preview < ApplicationViewComponentPreview
  def notice
    render_component Flash::Component.new(notice: "Business created.")
  end

  def alert
    render_component Flash::Component.new(alert: "Something went wrong.")
  end
end
