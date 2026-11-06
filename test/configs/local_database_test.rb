require "test_helper"

class LocalDatabaseTest < ActiveSupport::TestCase
  test "the main checkout uses port 5432" do
    with_checkout(git: :directory) do |root|
      assert_equal 5432, LocalDatabase.port(root:, env: {})
    end
  end

  test "ERMIDA_DB_PORT wins over the port file" do
    with_checkout(git: :file, port_file: "5433\n") do |root|
      assert_equal 5544, LocalDatabase.port(root:, env: {"ERMIDA_DB_PORT" => "5544"})
    end
  end

  test "a worktree uses the port its setup recorded" do
    with_checkout(git: :file, port_file: "5433") do |root|
      assert_equal 5433, LocalDatabase.port(root:, env: {})
    end
  end

  test "the recorded port may carry surrounding whitespace" do
    with_checkout(git: :file, port_file: "  5434 \n") do |root|
      assert_equal 5434, LocalDatabase.port(root:, env: {})
    end
  end

  test "a worktree without a port refuses to load, and says how to set one" do
    with_checkout(git: :file) do |root|
      error = assert_raises(LocalDatabase::PortMissing) { LocalDatabase.port(root:, env: {}) }

      assert_includes error.message, "bin/setup"
      assert_includes error.message, "ERMIDA_DB_PORT"
    end
  end

  test "a worktree with DATABASE_URL set does not need a port" do
    with_checkout(git: :file) do |root|
      assert_equal 5432, LocalDatabase.port(root:, env: {"DATABASE_URL" => "postgres://postgres@localhost:5432"})
    end
  end

  test "a tree without git, like the production image, uses 5432" do
    with_checkout(git: nil) do |root|
      assert_equal 5432, LocalDatabase.port(root:, env: {})
    end
  end

  private

  def with_checkout(git:, port_file: nil)
    Dir.mktmpdir do |root|
      case git
      when :directory then Dir.mkdir(File.join(root, ".git"))
      when :file then File.write(File.join(root, ".git"), "gitdir: /elsewhere/.git/worktrees/x\n")
      end
      File.write(File.join(root, ".ermida-db-port"), port_file) if port_file

      yield root
    end
  end
end
