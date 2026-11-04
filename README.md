# ermida

## Development

Development runs in Docker through [dip](https://github.com/bibendi/dip), following Evil Martians'
[Ruby on Whales](https://evilmartians.com/chronicles/ruby-on-whales-docker-for-ruby-rails-development).
The setup lives in `.dockerdev/` and is separate from the production `Dockerfile` (Kamal).

Requirements: Docker with Compose, dip (`gem install dip`; there is no current Homebrew formula), and
[mise](https://mise.jdx.dev), which `dip provision` uses to fetch [prek](https://prek.j178.dev).

```sh
dip provision        # build the image, start Postgres, install gems and JS packages, prepare the database
dip rails s          # server at http://localhost:3000 (debugger and binding.irb work here), plus Vite
dip rails c          # console
dip rails test       # tests
dip psql             # psql on the development database
dip bash             # shell in the app container
dip rubocop          # Standard
dip archspec check   # layer boundaries in Archspec.rb (also in CI and pre-commit)
dip bun add <pkg>    # JavaScript packages (Bun from the bundlebun gem)
```

- JavaScript and CSS live in `app/javascript` and are bundled by Vite. `dip rails s` starts the Vite dev
  server in the background (hot reload on port 3036); its logs: `dip compose logs -f vite`.
- `RESET_DOCKER=true dip provision` starts from scratch: it drops the gems and the databases.
- Containers run as your user (UID/GID in `.dockerdev/.env`, written by `dip provision`), so files they
  create in the project are not owned by root on Linux.
- Ports are published on `127.0.0.1` only. Postgres gets a random port: `docker port ermida_dev-postgres-1`.
- `dip provision` installs the Git pre-commit hooks in `prek.toml` (RuboCop through dip, plus prek's
  built-in checks). Run them by hand with `mise exec prek@0.5.7 -- prek run --all-files`.
- After changing `.dockerdev/Dockerfile`, `.dockerdev/Aptfile` or the build args, bump the image tag in
  `.dockerdev/compose.yml` and run `dip provision` again.
