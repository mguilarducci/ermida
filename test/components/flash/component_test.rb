require "test_helper"

class Flash::ComponentTest < ViewComponent::TestCase
  test "a notice renders as a success status" do
    render_inline Flash::Component.new(notice: "Business created.")

    assert_selector ".alert.alert-success[role=status]", count: 1, text: "Business created."
    assert_no_selector ".alert-error"
  end

  test "an alert renders as an error alert" do
    render_inline Flash::Component.new(alert: "Something went wrong.")

    assert_selector ".alert.alert-error[role=alert]", count: 1, text: "Something went wrong."
    assert_no_selector ".alert-success"
  end

  test "an empty flash renders nothing" do
    render_inline Flash::Component.new(notice: nil, alert: "")

    assert_no_selector ".alert"
  end

  test "every preview renders" do
    %i[notice alert].each { |name| render_preview(name, from: Flash::Preview) }

    assert_selector ".alert"
  end
end
