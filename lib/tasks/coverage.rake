namespace :coverage do
  # Line coverage of everything under app/ and lib/ (.simplecov) never goes below this. Raise it when coverage
  # rises; lower it only on purpose, in the pull request that needs it.
  floor = 90

  desc "Merge the test suites' coverage (.resultset.json under the coverage directory) and fail below the floor"
  task :check do
    require "simplecov"

    # Both suites write to <coverage directory>/.resultset.json, except in CI, which downloads each job's into its
    # own folder under it. The directory is coverage/, or COVERAGE_DIR in the development containers (.simplecov).
    pattern = File.join(SimpleCov.coverage_path, "**", ".resultset.json")
    resultsets = Dir[pattern]
    abort "coverage:check: nothing matches #{pattern}; run the tests first" if resultsets.empty?

    SimpleCov.collate(resultsets) do
      coverage(:line) { minimum floor }
    end
  end
end
