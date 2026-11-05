require "test_helper"

class FormField::ComponentTest < ViewComponent::TestCase
  test "a valid text field renders a fieldset with a label tied to its input" do
    render_inline FormField::Component.new(form: form_for(build(:business, name: "Padaria")), attribute: :name)

    assert_selector "fieldset.fieldset label.fieldset-legend[for=business_name]", text: "Name"
    assert_selector "fieldset.fieldset input.input#business_name[value=Padaria]"
    assert_no_selector ".input-error"
    assert_no_selector "[aria-invalid]"
  end

  test "a text field with errors marks the input and links it to the message" do
    business = build(:business, name: "")
    business.validate

    render_inline FormField::Component.new(form: form_for(business), attribute: :name)

    assert_selector "input.input.input-error#business_name[aria-invalid=true][aria-describedby=business_name_error]"
    assert_selector "p#business_name_error.label.text-error", text: "Name can't be blank"
  end

  test "a textarea field renders a textarea holding the value" do
    render_inline FormField::Component.new(
      form: form_for(build(:business, description: "Fresh bread daily.")),
      attribute: :description,
      as: :text_area
    )

    assert_selector "label.fieldset-legend[for=business_description]", text: "Description"
    assert_selector "textarea.textarea#business_description", text: "Fresh bread daily."
  end

  test "every preview renders" do
    %i[default with_errors textarea].each { |name| render_preview(name, from: FormField::Preview) }

    assert_selector "fieldset.fieldset"
  end

  private

  def form_for(business)
    ActionView::Helpers::FormBuilder.new(:business, business, vc_test_controller.view_context, {})
  end
end
