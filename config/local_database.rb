# The port of this checkout's development and test Postgres (config/database.yml).
#
# Each git worktree runs its own Postgres on its own port, which bin/setup picks and writes to
# .ermida-db-port, so that db:test:prepare in one worktree never resets another's databases. The
# main checkout uses 5432. A worktree with no port refuses to load rather than fall back to 5432,
# which is the main checkout's Postgres.
#
# Plain Ruby, no Rails: config/database.yml is read before the app loads, by every rake task and in
# every environment, including CI (which sets DATABASE_URL) and the production image build (no .git).
module LocalDatabase
  DEFAULT_PORT = 5432
  PORT_FILE = ".ermida-db-port"

  class PortMissing < StandardError; end

  def self.port(root: File.expand_path("..", __dir__), env: ENV)
    if !(port = env["ERMIDA_DB_PORT"].to_s.strip).empty?
      Integer(port)
    elsif File.exist?(port_file = File.join(root, PORT_FILE))
      Integer(File.read(port_file).strip)
    elsif File.file?(File.join(root, ".git")) && env["DATABASE_URL"].to_s.empty?
      raise PortMissing, <<~MESSAGE.split.join(" ")
        This git worktree (#{root}) has no Postgres port of its own, and the default, #{DEFAULT_PORT},
        is the main checkout's: db:test:prepare here would reset its databases. Run bin/setup, which
        picks a port and starts this worktree's Postgres, or set ERMIDA_DB_PORT=#{DEFAULT_PORT} to
        share the main checkout's Postgres on purpose.
      MESSAGE
    else
      DEFAULT_PORT
    end
  end
end
