---
title: In a worktree without node_modules, the test run is OOM-killed by a Vite build that calls itself
date: 2026-11-05
category: developer-experience
module: dev environment (dip, Vite, test suite)
problem_type: test_failure
component: development_workflow
symptoms:
  - "dip rails test stops after a few dozen dots with exit code 137 and no error, failure or stack trace"
  - "docker events shows oom events for the ermida_dev-rails-run-* container just before it dies"
  - "Running bin/vite build by hand prints nested \"Build with Vite failed!\" lines, each after its own Bundler home-directory warning"
root_cause: incomplete_setup
resolution_type: environment_setup
severity: medium
tags: [vite, vite-ruby, bundlebun, node-modules, worktree, oom, exit-137, dip]
---

# In a worktree without node_modules, the test run is OOM-killed by a Vite build that calls itself

## Problem

In a git worktree that has never run `dip provision` (or `bin/setup`), `dip rails test` dies partway through with exit 137 and prints nothing about why. The cause is a missing `node_modules`, so tests never get to report a failure.

## Symptoms

- The suite prints dots, then stops. The shell gets exit 137 (SIGKILL), with no `Failure:`, `Error:` or summary line. It happens with parallel workers, serially (`PARALLEL_WORKERS=1`), and in the background.
- A single test that renders no page passes on its own. A whole test file dies once it reaches a test that renders a page, such as `GET new_session_path`.
- `docker events --since 30m --until 0s --filter event=oom` lists repeated `oom` events for the `ermida_dev-rails-run-*` container, then a `die` with `exitCode=137`.
- `ls node_modules` and `ls public/vite-test` both report "No such file or directory".

## What Didn't Work

- Reading the test log: it ends mid-dots, because the container is killed before Minitest prints anything.
- Blaming a new test: tests added in the same change were the first suspects, but the unchanged `HEAD` version of a controller test file was OOM-killed the same way.
- Running the background job differently: a background run died the same way, so the agent's shell was not killing it.

## Solution

Install the JavaScript packages in the worktree. `bin/setup` does this with `bin/bun install`, and the first step of `bin/ci` runs `bin/setup`. By hand, `--frozen-lockfile` leaves `bun.lock` untouched:

```sh
bin/bun install --frozen-lockfile
bin/rails test
```

After the install the suite passed: 178 runs, 0 failures, on three seeds.

Before the fix described below, the first run after the install (or after `bin/setup`'s `tmp:clear`, the first step of `bin/ci`) also showed one to three `Vite Ruby can't find entrypoints/application.css in the manifests` errors. Every parallel worker started its own first Vite build, and some read the manifest while another build was rewriting it. `test/test_helper.rb` now calls `ViteRuby.commands.build` once, before `parallelize` forks the workers, so the workers find the build in place.

## Why This Works

The test environment builds assets on demand: `config/vite.json` sets `"autoBuild": true` and `"publicOutputDir": "vite-test"` for `test`. So the first test that renders the layout makes vite_ruby run the Vite binary configured as `"viteBinPath": "bin/bun-vite"`. That script runs `Bundlebun.call(['x', '--bun', 'vite', *ARGV])` after `require 'bundler/setup'` (`bin/bun-vite:7`, `bin/bun-vite:13`).

With no `node_modules`, `bun x vite` has no Vite package to run. In the dev container, `command -v vite` resolves to `/usr/local/bundle/bin/vite`, the vite_ruby gem's own executable. Per this session's observation, that is what `bun x` ends up running. vite_ruby then calls `bin/bun-vite` again, which boots Bundler and runs `bun x vite` again, and so on. Each level shows up as one more nested "Build with Vite failed!" line. The processes pile up until the container runs out of memory and Docker kills it.

Once `node_modules/.bin/vite` exists, `bun x vite` runs the real Vite and the loop never starts.

Worktrees share nothing in `node_modules`: each checkout has its own. Every new worktree needs its own install. Development has since moved from the dev container to the host; the loop is the same there, since vite_ruby's `vite` executable is on the gem path either way, and it ends when the machine runs out of memory instead of when Docker kills a container.

## Prevention

- Run `bin/setup`, or at least `bin/bun install --frozen-lockfile`, in every new worktree before running tests.
- When a test run dies with no output, check `ls node_modules` before suspecting the code under test.
- `bin/bun-vite` now stops with "node_modules is missing: run `bin/bun install`" when `node_modules/.bin/vite` does not exist. The test that renders the first page fails with that message instead of the process being killed. A test can't hold this lesson, because before the check the container was killed before any test result printed.

## Related Issues

- `.compound-engineering/artifacts/solutions/developer-experience/migrate-rewrites-solid-schema-dumps.md`: another trap of the dip-based dev environment. Its cause and fix are unrelated.
