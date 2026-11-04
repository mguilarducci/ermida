# Layer boundaries, checked statically by `archspec check` [https://archspecrb.dev]
# Earlier layers may use later ones, never the reverse. Folders the app doesn't have
# yet are listed too, so code placed in them is classified from the start.
source "app/**/*.rb"

architecture :layered, layers: {
  presentation: %w[
    app/controllers/**/*.rb
    app/views/**/*.rb
    app/components/**/*.rb
    app/helpers/**/*.rb
    app/presenters/**/*.rb
    app/serializers/**/*.rb
    app/forms/**/*.rb
    app/filters/**/*.rb
    app/channels/**/*.rb
    app/mailboxes/**/*.rb
    app/jobs/**/*.rb
  ],
  application: %w[
    app/services/**/*.rb
    app/operations/**/*.rb
    app/policies/**/*.rb
    app/mailers/**/*.rb
    app/deliveries/**/*.rb
    app/notifiers/**/*.rb
    app/agents/**/*.rb
  ],
  domain: %w[
    app/models/**/*.rb
    app/queries/**/*.rb
    app/values/**/*.rb
    app/repositories/**/*.rb
    app/configs/**/*.rb
  ],
  infrastructure: %w[
    app/clients/**/*.rb
  ]
}

# Controller APIs stay in controllers: bare calls to the request context
# from lower layers are reverse dependencies
application.cannot_call :render, :redirect_to, :params, :session, :cookies, :flash,
  receiver: :none
domain.cannot_call :render, :redirect_to, :params, :session, :cookies, :flash,
  receiver: :none

# Domain objects never read execution context: pass explicit parameters
domain.cannot_reference_constants "Current"

# A top-level app/<x>/ folder names a layer or a concept, never a vendor
component(:vendor_folders, in: "app/{sidekiq,temporal,redis,stripe,kafka}/**/*.rb")
  .must_be_empty(because: "vendor code goes one level deeper, e.g. app/clients/stripe/")
