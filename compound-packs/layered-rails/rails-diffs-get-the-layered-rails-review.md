---
title: A review of Rails code changes includes the layered-rails review workflow, not only archspec
applies_when:
  - reviewing a diff, branch or pull request that touches app/
tags: [layered-rails, review, layer-violations]
---

`archspec check` covers static boundaries only. The review also covers what it cannot see: business logic in
controllers, anemic models, request objects or params passed into services, notifications sent from models,
low-scoring callbacks, code-slicing concerns and god objects.

How: `.claude/skills/layered-rails/workflows/review.md`, also available as `/layered-rails-review` or the `layered-rails-reviewer` agent.
Violation catalog: `.claude/skills/layered-rails/references/anti-patterns/layer-violations.md`.
