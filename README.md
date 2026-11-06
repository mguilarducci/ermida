# ermida

## Development

Development runs on the host, as 37signals runs [Fizzy](https://github.com/basecamp/fizzy):
[mise](https://mise.jdx.dev) installs Ruby and the tools pinned in `.mise.toml`, Homebrew (macOS, `Brewfile`)
or pacman (Arch/Omarchy, `[bootstrap.packages]` in `.mise.toml`) installs the system packages, and only
Postgres runs in Docker. The production `Dockerfile` (Kamal) is separate.

Requirements: macOS with [Homebrew](https://brew.sh), or Arch/Omarchy with pacman; and Docker, for Postgres,
unless a Postgres 18 already listens on the checkout's port. `bin/setup` installs mise when it is missing.

```sh
bin/setup              # install everything, start Postgres, prepare the database, install the git hooks, start bin/dev
bin/dev                # server at http://localhost:3000, plus Vite (hot reload on 3036)
bin/rails console      # console
bin/rails test         # tests
bin/rails dbconsole    # psql on the development database
bin/ci                 # the whole local CI
bin/rubocop            # Standard
bin/bun add <pkg>      # JavaScript packages (Bun from the bundlebun gem)
```

- Run them from a shell where mise is activated, or prefix them with `mise exec --`.
- Each checkout gets its own Postgres: the main checkout on 5432 (the `ermida-postgres` container, or a
  Postgres already listening there that accepts `postgres`/`postgres`), each git worktree on its own port from
  5433 (the `ermida-postgres-<worktree directory>` container). `bin/setup` records a worktree's port in
  `.ermida-db-port`; a worktree that hasn't run it refuses to boot.
- `bin/dev` runs Rails and Vite through foreman (`Procfile.dev`). To stop at `debugger` or `binding.irb`, run
  `bin/rails server` and `bin/vite dev` in two terminals instead. `PORT=3100 bin/dev` serves on another port.
- `bin/setup --reset` also resets the development database. Running it again at any time is safe.
- If Vite fails to load a native module after moving off the old Docker setup, delete `node_modules` and run
  `bin/setup` again: the packages installed in the container were built for Linux.
- The old Docker development setup left volumes named `ermida_dev_*` (`docker volume ls`), which nothing uses
  any more and can be deleted.
