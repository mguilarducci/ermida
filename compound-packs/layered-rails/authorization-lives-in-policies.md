---
title: Authorization rules live in Action Policy policies, never inline in controllers, views or models
applies_when:
  - deciding who may see or do something
  - adding a permission check, role or admin-only action
  - scoping a listing to what the current user may access
tags: [layered-rails, authorization, action-policy, policies]
---

Each rule is a policy under `app/policies/` inheriting `ApplicationPolicy`; controllers and views ask the policy.
Models do not check permissions.

How: `references/patterns/policy-objects.md`, `references/topics/authorization.md`,
`references/gems/action-policy.md`, `examples/authorization-to-policy.md`.
