# An account's pages live under its slug: /accounts/edificio-aurora/businesses. This middleware moves that prefix
# from the path to SCRIPT_NAME, the way a mounted app is served, so routes stay unscoped and url helpers keep the
# prefix inside an account (`script_name: nil` leaves it). The AccountScoping concern turns the slug into
# Current.account. Route words under /accounts/ (Account::RESERVED_SLUGS) are never read as slugs.
module AccountSlug
  PATH = "/accounts"
  PREFIX = %r{\A#{PATH}/([a-z0-9_-]+)(?=/|\z)}
  ENV_KEY = "ermida.account_slug"

  class Extractor
    def initialize(app)
      @app = app
    end

    def call(env)
      request = ActionDispatch::Request.new(env)
      match = PREFIX.match(request.path_info)

      if match && !Account::RESERVED_SLUGS.include?(match[1])
        request.engine_script_name = request.script_name = match[0]
        request.path_info = match.post_match.presence || "/"
        env[ENV_KEY] = match[1]
      end

      @app.call(env)
    end
  end
end

Rails.application.config.middleware.insert_after Rack::TempfileReaper, AccountSlug::Extractor
