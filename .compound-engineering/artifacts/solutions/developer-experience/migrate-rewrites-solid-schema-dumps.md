---
title: Running a migration rewrites the Solid Cache, Queue and Cable schema dumps
date: 2026-11-04
category: developer-experience
module: database schema dumps
problem_type: developer_experience
component: development_workflow
severity: low
applies_when:
  - "Running dip rails db:migrate or a rollback in development"
  - "Committing a change that adds or edits a migration"
tags: [migrations, schema-dump, solid-queue, solid-cache, solid-cable, multi-database]
---

# Running a migration rewrites the Solid Cache, Queue and Cable schema dumps

## Context

The app keeps Solid Cache, Solid Queue and Solid Cable in their own databases, each with a committed schema file: `db/cache_schema.rb`, `db/queue_schema.rb` and `db/cable_schema.rb`. Those files came from the gems' installers, not from a dump of this app's Postgres databases.

In development Rails dumps every database's schema after `db:migrate`, including the three Solid ones, even when the migration only touches the primary database. The dump does not match the committed files, so the first migration in a branch leaves about 270 lines of changes in files that have nothing to do with it. Seen while adding the `businesses` table: `git status` showed the three Solid schemas modified next to `db/schema.rb`.

The changes are cosmetic: the `Schema[7.1]` header becomes `Schema[8.1]` with the auto-generated comment block, `enable_extension "pg_catalog.plpgsql"` appears, `t.binary ... limit:` loses its limit, `t.integer ... limit: 8` becomes `t.bigint`, and the queue schema's tables are reordered. Nothing about the Solid tables actually changes.

## Guidance

After running a migration in development, restore the three Solid schema files before committing, so only `db/schema.rb` carries the change:

```sh
git checkout HEAD -- db/cable_schema.rb db/cache_schema.rb db/queue_schema.rb
```

Check `git status` before committing a migration; any of those three files showing as modified without a Solid-related change is this rewrite.

The lasting fix is to regenerate the three files once from the development databases and commit them in a change of their own. After that, a migration produces no diff in them. That is a deliberate commit to the production schema files, so it was not done as part of the feature that ran into this.

## Why This Matters

Committing the rewrite buries a one-table migration under hundreds of unrelated lines in the production queue, cache and cable schemas, which reviewers then have to read or wave through. Nothing in the final code shows the trap, and it repeats on every branch that adds a migration until the files are regenerated.

## When to Apply

- Every branch that runs a migration in development, until the Solid schema files have been regenerated and committed once.
- Delete this note after that regeneration lands and a migration leaves the three files untouched.

## Examples

On the `businesses` branch, after `dip rails db:migrate`:

```text
 M db/cable_schema.rb
 M db/cache_schema.rb
 M db/queue_schema.rb
 M db/schema.rb
```

After restoring the three Solid files, only `db/schema.rb` remained, holding the new `businesses` table and the bumped schema version.

A related multi-database detail from the same session: a bare `dip rails db:rollback` refuses to run here and asks for a database, so roll back the app's own tables with `dip rails db:rollback:primary`.

## Related

- Plan for the change that hit this: `.compound-engineering/artifacts/plans/2026-11-04-1951-feat-businesses-crud-plan.md` (its model unit restores the three files after migrating).
