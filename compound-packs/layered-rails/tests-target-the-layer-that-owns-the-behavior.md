---
title: Tests verify each behavior in the layer that owns it; controller and system tests do not re-test business logic
applies_when:
  - writing or changing tests
  - testing business rules reached through a controller or job
tags: [layered-rails, testing]
---

Business logic is tested in model (or domain object) tests; controller tests cover HTTP concerns.

How: `references/anti-patterns/testing.md`.
