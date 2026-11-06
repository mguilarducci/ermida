# Coverage settings, read whenever simplecov is required: by test/test_helper.rb, which starts it,
# and by `bin/rails coverage:check` (lib/tasks/coverage.rake), which merges the suites and holds the floor.
SimpleCov.configure do
  # Groups by layer, and merges the coverage of the workers `parallelize` forks
  load_profile "rails"

  # Every file counts, loaded or not: tests don't eager load, so a file no test touches would
  # otherwise be left out instead of counting as uncovered
  cover "{app,lib}/**/*.rb"
  # Lookbook previews run only in development
  skip %r{\Aapp/components/(.+/)?(application_view_component_)?preview\.rb\z}

  # `bin/ci` runs the system tests minutes after the others; keep both for the merge
  merge_timeout 3600

  # The development containers keep it off the bind mount (COVERAGE_DIR in .dockerdev/compose.yml)
  coverage_dir ENV.fetch("COVERAGE_DIR", "coverage")
end
