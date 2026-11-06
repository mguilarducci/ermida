require_relative "boot"
# Read by config/database.yml, which every rake task loads before the app
require_relative "local_database"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Ermida
  class Application < Rails::Application
    # Configure the path for configuration classes that should be used before initialization
    # NOTE: path should be relative to the project root (Rails.root)
    # config.anyway_config.autoload_static_config_path = "config/configs"
    #
    # Raise on unknown keys in YAML and credentials (catches typos in config files)
    config.anyway_config.enforce_config_schema = true

    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.1

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Component previews (Lookbook) live next to their components
    config.view_component.previews.paths << Rails.root.join("app/components")

    # A redirect to a join page carries its code, which lets anyone who has it join
    config.filter_redirect << %r{/join/}

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")
  end
end
