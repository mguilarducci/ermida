# Run using bin/ci

CI.run do
  step "Setup", "bin/setup --skip-server"

  step "Style: Ruby", "bin/rubocop"
  step "Architecture: Layer boundaries", "bundle exec archspec check"

  step "Security: Gem audit", "bin/bundler-audit"
  step "Security: JavaScript package audit", "bin/bun audit"
  step "Security: Brakeman code analysis", "bin/brakeman --quiet --no-pager --exit-on-warn --exit-on-error"
  # Coverage left by earlier runs would count toward this one's merge
  step "Tests: Reset coverage", "rm -rf \"${COVERAGE_DIR:-coverage}\""
  step "Tests: Rails", "bin/rails db:test:prepare test"
  # Boots the app the way the server and console do; the test steps go through rake, which hides a broken boot
  step "Tests: Boot", "bin/rails runner 'puts \"booted\"'"
  step "Tests: Seeds", "env RAILS_ENV=test bin/rails db:seed:replant"

  # Needs a browser: CHROME_URL (set by `dip ci`) or a local Chrome
  step "Tests: System", "bin/rails test:system"
  step "Tests: Coverage", "bin/rails coverage:check"

  # Optional: set a green GitHub commit status to unblock PR merge.
  # Requires the `gh` CLI and `gh extension install basecamp/gh-signoff`.
  # if success?
  #   step "Signoff: All systems go. Ready for merge and deploy.", "gh signoff"
  # else
  #   failure "Signoff: CI failed. Do not merge or deploy.", "Fix the issues and try again."
  # end
end
