# How people sign in.
class AuthenticationConfig < ApplicationConfig
  # Shows the emailed code on the code page too, so development needs no inbox. Anyone who opens that page can then
  # sign in as the person, so the config refuses to load with it on outside development.
  attr_config show_code_on_page: false

  on_load do
    if show_code_on_page && !Rails.env.development?
      raise_validation_error "show_code_on_page must stay off outside development"
    end
  end
end
