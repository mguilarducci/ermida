---
title: A review of Rails code changes includes the layered-rails review workflow, not only archspec
applies_when:
  - reviewing a diff, branch or pull request that touches app/
tags: [layered-rails, review, layer-violations]
---

`archspec check` covers static boundaries only. The review also covers what it cannot see: business logic in
controllers, anemic models, request objects or params passed into services, notifications sent from models,
low-scoring callbacks, code-slicing concerns and god objects.

How: `workflows/review.md`.
Violation catalog: `references/anti-patterns/layer-violations.md`.
