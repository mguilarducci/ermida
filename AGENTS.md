# AGENTS.md

This file provides guidance to coding agents working with code in this repository.

## What this is

Ermida, a Rails 8.1 application (Ruby 4.0, PostgreSQL 18, Hotwire, Vite on Bun, Minitest, Standard). Most of
the app is base classes and wiring; the gem stack is curated and commented by purpose in the `Gemfile`, so read
that before adding a gem that might duplicate one already there.

## Commands

Development runs in Docker through [dip](https://github.com/bibendi/dip) (setup in `.dockerdev/`, separate from
the production `Dockerfile` used by Kamal). Run Ruby, Rails and Bun commands through `dip`, not on the host.

```sh
dip provision                              # build image, start Postgres, bundle, bun install, db:prepare, install prek hooks
dip rails s                                # server on :3000 plus the Vite dev server on :3036
dip rails test                             # whole suite
dip rails test test/models/foo_test.rb:42  # one file, or one test by line
dip rails test:system                      # system tests, against the chrome service
dip ci                                     # bin/ci: the whole local CI, system tests included
dip rubocop                                # Standard, through RuboCop (-a to autocorrect)
dip archspec check                         # layer boundaries from Archspec.rb
dip bun add <pkg>                          # JavaScript packages
dip bash                                   # shell in the app container
```

- `RAILS_ENV` is empty in the containers on purpose, so `bin/rails test` switches to test by itself.
- Development-only tools under http://localhost:3000: `/jobs` (Mission Control), `/pghero`, `/letter_opener`
  (every email sent in development lands here) and `/lookbook` (component previews). None is mounted in
  production.
- N+1 queries show in a footer on development pages and fail tests (Prosopite). strong_migrations stops unsafe
  migrations, and runs each migration with lock and statement timeouts.
- Test helpers (`test/test_helper.rb`): FactoryBot methods (factories in `test/factories/`), WebMock blocking real
  HTTP (record a needed call once with VCR into `test/cassettes/`), n_plus_one_control's
  `assert_perform_constant_number_of_queries`, and `with_model` for throwaway tables when testing concerns.
  Every page needs a session, so controller tests call `sign_in_as(identity)` (`test/test_helpers/`) and
  system tests call their own `sign_in_as(identity)`, which writes the session cookie into the browser.
  Rate limits count in the controller cache, a memory store in tests that integration tests clear before each
  test; a test that repeats one request to trip a limit wraps the repeats in `Prosopite.pause`.
- System tests (`test/system/`, `ApplicationSystemTestCase`) drive headless Chrome through Cuprite, with
  capybara-lockstep in the layout. The dev image has no Chrome: in Docker they connect to the `chrome` service
  (browserless) through `CHROME_URL`, which only `dip rails test:system` and `dip ci` set (they stop the
  service when they finish), so plain `dip rails test test/system/...` fails. GitHub CI launches its own Chrome.
- The pre-commit hooks (`prek.toml`) run RuboCop and archspec through dip, so Docker must be running to commit.
  Run them by hand with `mise exec prek@0.5.7 -- prek run --all-files`.
- CI is `.github/workflows/ci.yml`: brakeman, bundler-audit, `bun audit`, rubocop, archspec, tests and
  system tests. `bin/ci` (`config/ci.rb`) runs a local version: setup, rubocop, archspec, the audits, brakeman,
  tests, seeds and system tests.
- After changing `.dockerdev/Dockerfile`, `.dockerdev/Aptfile` or build args, bump the image tag in
  `.dockerdev/compose.yml` and run `dip provision` again.

## Architecture

The app follows layered design ("Layered Design for Ruby on Rails Applications"), enforced statically by
`Archspec.rb` in CI and pre-commit. Layers, from top to bottom; a layer may use the ones below it, never above:

- **presentation**: controllers, views, components, helpers, presenters, serializers, forms, filters, channels, jobs
- **application**: services, operations, policies, mailers, deliveries, notifiers, agents
- **domain**: models, queries, values, repositories, configs
- **infrastructure**: clients (vendor code goes one level deeper, e.g. `app/clients/stripe/`; folders like
  `app/stripe/` are rejected)

Lower layers must not call `render`, `redirect_to`, `params`, `session`, `cookies` or `flash`, and models must
not reference `Current`; pass explicit parameters instead. Archspec only sees static boundaries; the rest of
the design is covered by the `layered-rails` skill (see "Planning and reviewing" below).

Building blocks and their base classes:

- **Components**: `ApplicationViewComponent` (view_component-contrib). Previews inherit
  `ApplicationViewComponentPreview`, can sit next to their component, and show in Lookbook.
- **Forms**: `ApplicationForm` (`app/forms/`), for input from one screen that writes several models. A form
  declares attributes and validations and implements `submit!`; `save` validates, then runs `submit!` in a
  transaction. `AccountForm` is the example.
- **Notifications**: `ApplicationDelivery` (Active Delivery). `PostsDelivery.published(post)` fans out to
  `PostsMailer.published` and any other channel.
- **Authentication**: the `Authentication` concern in `ApplicationController` requires a session on every page;
  controllers opt out with `allow_unauthenticated_access`, or `require_unauthenticated_access` for pages only a
  signed-out person needs. Sessions belong to an `Identity` (a person), and a `User` is that identity's place in
  one `Account` (a condominium). Only the concern sets `Current` (session, identity, user, account), and nothing
  sets the account yet, so `Current.user` is nil. People sign in, and sign up to create an account, with a
  6-character code emailed to them (`MagicLink`, `Authentication::ViaMagicLink`, with `SignInForm` and
  `SignupForm` sending it); in development the code page also shows the code (`AuthenticationConfig`, which
  refuses to load with that on in any other environment). The home page (`/`) lists the signed-in person's accounts. Mission Control is kept
  outside it in development.
- **Authorization**: `ApplicationPolicy` (Action Policy), which gets the user from the controller's
  `current_user`.
- **Configuration**: classes inheriting `ApplicationConfig` (Anyway Config), read as class methods: in
  `config/configs/` when boot code reads them, otherwise in `app/configs/` (domain layer, checked by Archspec). `enforce_config_schema` is on, so unknown keys in YAML or credentials raise. Use the `anyway-config`
  skill rather than reading `ENV` or credentials directly.
- **Feature flags**: Flipper, stored in the database.
- **Jobs, cache, cable**: Solid Queue, Cache and Cable on Postgres, each on its own database, in development as
  in production. `dip rails s` runs the Solid Queue worker inside Puma (`SOLID_QUEUE_IN_PUMA`); tests use the
  Active Job and Action Cable test adapters.
- **Frontend**: entry points in `app/javascript/entrypoints/`, Stimulus controllers in
  `app/javascript/controllers/`, loaded in the layout with `vite_javascript_tag`/`vite_stylesheet_tag`.
  There is no importmap. Styles are Tailwind CSS 4 with daisyUI 5, through the `@tailwindcss/vite` plugin;
  the daisyUI themes (light by default, dark when the system prefers it) are set in
  `app/javascript/entrypoints/application.css`, and Tailwind only reads class names under `app/`.
- **Metrics and logs**: Yabeda collects Rails, Active Job and Puma metrics; Puma exports them for Prometheus on
  `:9394/metrics` (not published by compose or Kamal). Processes share them through `tmp/prometheus/`, because
  Solid Queue workers are forked. Production logs one line per request (Lograge).

## Planning and reviewing

We are adopting the layered design principles from "Layered Design for Ruby on Rails Applications": clean
abstraction boundaries, explicit layers and specification tests. The `layered-rails` skill is installed per
user, outside the repo; the paths below are relative to its folder.

- **Planning** a feature or an architectural change (including `ce-brainstorm`, `ce-plan` and `ce-work`): use
  the `layered-rails` skill for the analysis.
  - `workflows/plan.md`: plan incremental adoption of layered patterns
  - `workflows/analyze.md`: architecture analysis of the codebase or a folder
  - `workflows/spec-test.md`: apply the specification test to decide layer placement
- **Reviewing** Rails changes (including `ce-code-review` and `ce-doc-review`): also follow the skill's
  `workflows/review.md` to check for layer violations.

The `layered-rails` Compound Pack (`compound-packs/layered-rails/`, declared in `.compound-engineering/config.yaml`)
holds the situational rules: which pattern fits each kind of change and which skill file covers it. Planning
and review cite it as `(pack: layered-rails, <file>)`.

## Tooling for agents

- The `rails-hyperdrive` MCP server (`.mcp.json`) is served by the running app at `/_hyperdrive/mcp`, so it
  only works while `dip rails s` is up. It gives routes, models, source locations, SQL and logs.
- Compound Engineering is configured in `.compound-engineering/config.yaml`; its artifacts (plans,
  brainstorms, solutions) live under `.compound-engineering/artifacts/`.
  `.compound-engineering/artifacts/solutions/` holds documented solutions to past problems (bugs, best
  practices, workflow patterns), organized by category with YAML frontmatter (module, tags, problem_type);
  relevant when implementing or debugging in an area it covers.
- `CONCEPTS.md`: shared domain vocabulary (entities, named processes, status concepts); relevant when orienting
  to the codebase or discussing domain concepts.

## Conventions

- `CODING_STANDARDS.md`: the rules Ruby code here follows beyond Standard and Archspec. Read it before writing
  or reviewing code, and update it when a change establishes or retires a rule.
- `REVIEW.md`: how review behaves here (it includes `CODING_STANDARDS.md`). Read it before reviewing code, and
  update it when the team's review policy changes.
- Commit messages are one imperative line that states the outcome and why, e.g. "Keep bundlebun below 0.5.1
  so the app boots outside rake".
- Gem version constraints in the `Gemfile` carry a comment when they pin around a bug; keep it current.
- After a solved, verified problem, automatically invoke the `ce-compound` skill with
  `mode:non-interactive` at the completion checkpoint only when the work produced durable project
  reasoning that is not readily recoverable from the final code, tests, types, comments, or existing
  documentation, and losing it would plausibly cause recurrence, material risk, or substantial
  rediscovery. Apply this counterfactual: if the learning document disappeared, would a future engineer
  reading the final implementation still be likely to repeat the mistake or redo substantial
  investigation? If not, do not invoke it. Completion, effort, and diff size alone are not enough.
  Capture at the checkpoint so a qualifying learning can ship in the PR that produced it, and only where
  the repository treats captured learnings as tracked, committed knowledge.
- Write every report, summary, or handoff to the user through the `ce-noslop` skill. This applies when
  you are the top-level agent writing to the user, not when you are a subagent reporting to its caller.
  Do not apply it to code, config, verbatim quotes, or text the user asked to post as written.
