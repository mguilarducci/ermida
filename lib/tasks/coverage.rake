namespace :coverage do
  # Line coverage of everything under app/ and lib/ (.simplecov) never goes below this. Raise it when coverage
  # rises; lower it only on purpose, in the pull request that needs it.
  floor = 90

  desc "Merge the test suites' coverage (coverage/**/.resultset.json) and fail below the floor"
  task :check do
    require "simplecov"

    # Locally both suites write to coverage/.resultset.json; CI downloads each job's into its own folder under coverage/
    resultsets = Dir["coverage/**/.resultset.json"]
    abort "coverage:check: no coverage/**/.resultset.json; run the tests first" if resultsets.empty?

    SimpleCov.collate(resultsets) do
      coverage(:line) { minimum floor }
    end
  end
end
