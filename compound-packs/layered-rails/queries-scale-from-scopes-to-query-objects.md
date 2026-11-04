---
title: Queries start as scopes, grow into query objects when complex or reused, and use repositories only as a last resort
applies_when:
  - writing a complex or reused database query
  - adding reporting or search queries
  - considering a repository or data-access class
tags: [layered-rails, queries, scopes, query-objects]
---

Simple queries are scopes on the model. Complex, reused query building goes in a query object under
`app/queries/` (domain layer). A repository is justified only when returning custom domain objects that scopes
and query objects cannot express.

How: `.claude/skills/layered-rails/references/patterns/query-objects.md`, `.claude/skills/layered-rails/references/patterns/repositories.md`,
`.claude/skills/layered-rails/examples/query-to-query-object.md`.
