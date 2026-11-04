class FormField::Component < ApplicationViewComponent
  CONTROL_CLASSES = {text_field: "input", text_area: "textarea"}.freeze

  def initialize(form:, attribute:, as: :text_field)
    @form = form
    @attribute = attribute
    @as = as
  end

  private

  attr_reader :form, :attribute, :as

  def control
    form.public_send(as, attribute, class: control_class, aria: control_aria)
  end

  def control_class
    base = CONTROL_CLASSES.fetch(as)
    if errors?
      "#{base} #{base}-error"
    else
      base
    end
  end

  def control_aria
    if errors?
      {invalid: true, describedby: error_id}
    else
      {}
    end
  end

  def errors? = form.object.errors.include?(attribute)

  def error_id = form.field_id(attribute, :error)

  def error_message = form.object.errors.full_messages_for(attribute).to_sentence
end
