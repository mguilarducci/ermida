source "https://rubygems.org"

# ==============================================================================
# Core
# ==============================================================================

gem "rails", "~> 8.1.4", ">= 8.1.4.1"

# PostgreSQL (required by pg_search, postgresql_cursor, strong_migrations, pghero)
gem "pg", "~> 1.7"

# Use the Puma web server [https://github.com/puma/puma]
gem "puma", ">= 5.0"

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[windows jruby]

# ==============================================================================
# Jobs, cache and Action Cable (database-backed Solid stack)
# ==============================================================================

gem "solid_cache"
gem "solid_queue"
gem "solid_cable"

# Web UI to monitor and manage job queues (needs propshaft, see Assets)
gem "mission_control-jobs"

# ==============================================================================
# Deploy
# ==============================================================================

# Deploy this application anywhere as a Docker container [https://kamal-deploy.org]
gem "kamal", require: false

# HTTP asset caching/compression and X-Sendfile acceleration for Puma [https://github.com/basecamp/thruster]
gem "thruster", require: false

# ==============================================================================
# Assets and frontend (Vite + Hotwire)
# ==============================================================================

# Bundle JS/CSS with Vite [https://vite-ruby.netlify.app]
gem "vite_rails"
# Bun runtime packaged as a gem, used by Vite; no Node.js needed [https://github.com/yaroslav/bundlebun]
# Floor: 0.5+ ships only -gnu/-musl builds, so a lockfile with generic linux
# platforms would otherwise fall back silently to an old Bun (0.3.0 / Bun 1.3.8).
# Ceiling: 0.5.1 calls Rake.load_rakefile whenever Rake is defined, but Rails defines
# Rake partially, so every boot outside rake crashes. Lift it once that is fixed.
gem "bundlebun", ">= 0.5", "< 0.5.2"
# Serves assets of engines that ship their own (mission_control-jobs requires it even with Vite)
gem "propshaft"
# Hotwire's SPA-like page accelerator [https://turbo.hotwired.dev]
gem "turbo-rails"

# ==============================================================================
# Views
# ==============================================================================

# UI components [https://viewcomponent.org]
gem "view_component", "~> 4.22"
gem "view_component-contrib", "~> 0.2.5"
# HTML-aware ERB: validation and debug tools for views (0.x; reactive APIs are experimental)
gem "reactionview", "~> 0.6.0"
# HTML+ERB parser: engine behind reactionview, also `herb analyze` [https://github.com/marcoroth/herb]
gem "herb", "~> 0.11.1", require: false

# ==============================================================================
# Active Record extensions
# ==============================================================================

# Type casting for store_accessor/JSONB attributes
gem "store_attribute", "~> 2.2"
# PostgreSQL full-text search
gem "pg_search", "~> 2.4"
# Server-side cursors to iterate over large result sets
gem "postgresql_cursor", "~> 0.6.11"
# Soft-deletion
gem "discard", "~> 2.0"
# Pagination (43.x is a full rewrite of 9.x)
gem "pagy", "~> 43.8"
# Helpers to group by time periods
gem "groupdate", "~> 6.8"
# Collaborator objects attached to models (has_object)
gem "active_record-associated_object", "~> 1.0"
# Generate jobs from model methods (performs)
gem "active_job-performs", "~> 1.0"
# Run callbacks after the current DB transaction commits, outside of models
gem "after_commit_everywhere", "~> 1.6"
# Validations backed by database constraints (unique indexes, foreign keys)
gem "database_validations", "~> 2.1"

# ==============================================================================
# Database operations
# ==============================================================================

# Make sure your migrations do not cause downtimes
gem "strong_migrations"
# PostgreSQL health dashboard (engine; query stats need pg_stat_statements)
gem "pghero"
# Partial anonymized dumps of production data for local profiling
gem "evil-seed", require: false

# ==============================================================================
# Authentication and authorization
# ==============================================================================

# has_secure_password, used by `bin/rails generate authentication`
gem "bcrypt", "~> 3.1.22"
# Authorization policies [https://actionpolicy.evilmartians.io]
gem "action_policy", "~> 0.7.8"

# ==============================================================================
# Application building blocks
# ==============================================================================

# Configuration classes [https://github.com/palkan/anyway_config]
gem "anyway_config", "~> 2.9"
# Notifications (mailers and other delivery channels)
gem "active_delivery", "~> 1.2"
# Feature flags stored in the database (brings in flipper)
gem "flipper-active_record", "~> 1.4"

# ==============================================================================
# Active Storage
# ==============================================================================

# Use Active Storage variants [https://guides.rubyonrails.org/active_storage_overview.html#transforming-images]
gem "image_processing", "~> 2.2"
# libvips bindings: a soft dependency since image_processing 2.0
gem "ruby-vips", "~> 2.3", require: false

# ==============================================================================
# Observability
# ==============================================================================

# Metrics for Rails requests, Active Job (Solid Queue) and Puma, exported to Prometheus
gem "yabeda-rails"
gem "yabeda-activejob"
gem "yabeda-puma-plugin", require: false
gem "yabeda-prometheus"
# prometheus-client 4.x (the most yabeda-prometheus 0.9 allows) calls CGI.parse in its multi-process file store,
# and Ruby 4.0 only ships cgi/escape. Drop this once yabeda-prometheus accepts prometheus-client 5, which no
# longer needs it.
gem "cgi", "~> 0.5", require: false

group :production do
  # Single-line structured request logs
  gem "lograge"
end

# ==============================================================================
# Development and test
# ==============================================================================

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", platforms: %i[mri windows], require: "debug/prelude"

  # Audits gems for known security defects (use config/bundler-audit.yml to ignore issues)
  gem "bundler-audit", require: false
  # Static analysis for security vulnerabilities [https://brakemanscanner.org]
  gem "brakeman", require: false

  # Factories instead of fixtures (also hooks into Rails generators)
  gem "factory_bot_rails"

  # Detects non-atomic interactions (HTTP calls, jobs, emails) inside DB transactions
  gem "isolator"
  # Required by isolator's sniffer dependency; a bundled (not default) gem since Ruby 4.0
  gem "benchmark"

  # Detect N+1 queries (dev middleware, raises in tests)
  gem "prosopite"

  # stackprof powers rack-mini-profiler flamegraphs and derailed; vernier is for test-prof (TEST_VERNIER)
  gem "stackprof"
  gem "vernier", require: false

  # Ruby style and lint (Standard)
  eval_gemfile "gemfiles/rubocop.gemfile"
  # Layer boundaries as static checks (Archspec.rb) [https://archspecrb.dev]
  gem "archspec", "~> 1.2", require: false
end

group :development do
  # Use console on exceptions pages [https://github.com/rails/web-console]
  gem "web-console"

  # Must come after pg so it can instrument SQL
  gem "rack-mini-profiler"
  gem "derailed_benchmarks"

  # Browse sent emails at /letter_opener
  gem "letter_opener_web"

  # Component previews and docs for ViewComponent [https://lookbook.build]
  gem "lookbook"

  # Checks that the schema matches model validations (CLI)
  gem "database_consistency", require: false
end

group :test do
  # System tests with Chrome over CDP (no Selenium)
  gem "capybara"
  gem "cuprite"
  # Makes Capybara wait for JS, AJAX and image loads
  gem "capybara-lockstep"
  # Page objects
  gem "site_prism"

  # Temporary models backed by temporary tables, for testing concerns
  gem "with_model"
  # N+1 regression assertions
  gem "n_plus_one_control"

  # Block real HTTP and record/replay it
  gem "webmock"
  gem "vcr"

  # Profile and speed up the test suite
  gem "test-prof"
end

gem "rails-hyperdrive", "~> 0.10.1", group: :development
gem "layered-rails-skills", "~> 3.1", group: :development
