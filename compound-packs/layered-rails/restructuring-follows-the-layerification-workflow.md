---
title: Restructuring existing Rails code follows the layered-rails layerification workflow, in small phases with a stop point each
applies_when:
  - planning a refactor of existing models, controllers, services or jobs
  - introducing a pattern the app does not use yet, such as policies, form objects, presenters or state machines
  - auditing the codebase for architecture problems
tags: [layered-rails, refactor, plan, analysis]
---

Restructuring is incremental: each phase is shippable on its own and says when to stop. Base the phases on an
analysis of the current code, not on a full rewrite.

How: `.claude/skills/layered-rails/workflows/plan.md` (`/layered-rails-plan [goal]` or the `layered-rails-planner` agent), with the
before/after templates in `.claude/skills/layered-rails/examples/`. Analyses: `/layered-rails-analyze`, `/layered-rails-analyze-gods`,
`/layered-rails-analyze-callbacks`, `/layered-rails-analyze-services`.
