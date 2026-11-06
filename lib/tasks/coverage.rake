namespace :coverage do
  # Line coverage of everything under app/ and lib/ (.simplecov) never goes below this. Raise it when coverage
  # rises; lower it only on purpose, in the pull request that needs it.
  floor = 90

  desc "Merge the test suites' coverage (.resultset.json under the coverage directory) and fail below the floor"
  task :check do
    require "simplecov"

    # Both suites write to coverage/.resultset.json, except in CI, which downloads each job's into its own folder
    # under coverage/.
    # The merge writes its own result and report to merged/, left out here: read back next time, that old merge
    # would keep counting lines no current test covers.
    merged = File.join(SimpleCov.coverage_path, "merged")
    pattern = File.join(SimpleCov.coverage_path, "**", ".resultset.json")
    resultsets = Dir[pattern].reject { |path| path.start_with?("#{merged}/") }
    abort "coverage:check: nothing matches #{pattern}; run the tests first" if resultsets.empty?

    SimpleCov.collate(resultsets) do
      coverage_dir merged
      coverage(:line) { minimum floor }
    end

    # collate exits on its own below the floor, so getting here means it passed or had nothing to measure
    abort "coverage:check: #{resultsets.join(", ")} held no coverage; run the tests first" unless SimpleCov.result?
  end
end
