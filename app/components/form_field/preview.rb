class FormField::Preview < ApplicationViewComponentPreview
  def default
    render_with_template(template: "form_field/preview_form", locals: {business: Business.new(name: "Padaria do João")})
  end

  def with_errors
    business = Business.new(name: "")
    business.validate
    render_with_template(template: "form_field/preview_form", locals: {business:})
  end

  def textarea
    render_with_template(
      template: "form_field/preview_form",
      locals: {business: Business.new(description: "Fresh bread daily."), attribute: :description, as: :text_area}
    )
  end
end
